#!/bin/bash

set -uo pipefail
# Note: removed 'e' flag to allow continuation on non-critical errors

# Hardcoded configuration values
SERVER_IP="0.0.0.0.0"
SERVER_USER="root"
SERVER_PORT="22"
REMOTE_PATH="/"
USE_YARN="y"  # Use yarn instead of npm

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handler
error_exit() {
    log_error "$1"
    exit 1
}

# Check if required commands exist
check_requirements() {
    log_info "Checking requirements..."
    
    if ! command -v ssh &> /dev/null; then
        error_exit "ssh command not found"
    fi
    
    if ! command -v scp &> /dev/null; then
        error_exit "scp command not found"
    fi
    
    if ! command -v tar &> /dev/null; then
        error_exit "tar command not found (required for archiving)"
    fi
    
    if [ "$USE_YARN" = "y" ]; then
        if ! command -v yarn &> /dev/null; then
            error_exit "yarn command not found"
        fi
    else
        if ! command -v npm &> /dev/null; then
            error_exit "npm command not found"
        fi
    fi
    
    log_info "All requirements met"
}

# Test SSH connection
test_ssh_connection() {
    log_info "Testing SSH connection to $SERVER_USER@$SERVER_IP:$SERVER_PORT..."
    
    if ssh -p "$SERVER_PORT" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "echo 'Connection successful'" &> /dev/null; then
        log_info "SSH connection successful"
    else
        error_exit "Failed to connect to server. Please check your SSH credentials and network connection."
    fi
}

# Build project locally
build_locally() {
    log_info "Building project locally..."
    
    if [ "$USE_YARN" = "y" ]; then
        log_info "Installing dependencies with Yarn..."
        if ! yarn install --frozen-lockfile; then
            error_exit "Failed to install dependencies with Yarn"
        fi
        
        log_info "Building Next.js with Yarn..."
        if ! yarn build; then
            error_exit "Failed to build with Yarn"
        fi
    else
        log_info "Installing dependencies with npm..."
        if ! npm ci; then
            error_exit "Failed to install dependencies with npm"
        fi
        
        log_info "Building Next.js with npm..."
        if ! npm run build; then
            error_exit "Failed to build with npm"
        fi
    fi
    
    log_info "Local build completed successfully"
}

# Create archive using tar (built-in shell command)
create_archive() {
    ARCHIVE_NAME="next-deploy-$(date +%s).tar.gz"
    ARCHIVE_PATH="/tmp/$ARCHIVE_NAME"
    
    log_info "Creating archive: $ARCHIVE_NAME"
    log_info "Including .next folder and all necessary files..."
    
    # Remove old archive if exists
    rm -f "$ARCHIVE_PATH" 2>/dev/null || true
    
    # Create archive using tar with gzip compression
    # Exclude: node_modules, .git, .github, document, logs, and the archive itself
    if tar --exclude='node_modules' \
           --exclude='.git' \
           --exclude='.github' \
           --exclude='document' \
           --exclude='logs' \
           --exclude="$ARCHIVE_NAME" \
           --exclude='*.tar.gz' \
           -czf "$ARCHIVE_PATH" \
           . 2>/dev/null; then
        log_info "Archive created successfully: $ARCHIVE_PATH"
        
        # Get archive size
        ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
        log_info "Archive size: $ARCHIVE_SIZE"
        
        ARCHIVE_NAME="$ARCHIVE_NAME"
        return 0
    else
        error_exit "Failed to create archive"
    fi
}

# Upload archive to server
upload_archive() {
    log_info "Uploading archive to server..."
    
    if scp -P "$SERVER_PORT" -o StrictHostKeyChecking=no "$ARCHIVE_PATH" "$SERVER_USER@$SERVER_IP:/tmp/$ARCHIVE_NAME" 2>&1; then
        log_info "Archive uploaded successfully"
        
        # Cleanup local archive
        log_info "Cleaning up local archive..."
        rm -f "$ARCHIVE_PATH" 2>/dev/null || log_warn "Failed to cleanup local archive (non-critical)"
        
        return 0
    else
        error_exit "Failed to upload archive to server"
    fi
}

# Deploy on server
deploy_on_server() {
    log_info "Connecting to server and deploying..."
    
    ssh -p "$SERVER_PORT" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" <<EOF
set -uo pipefail
# Note: removed 'e' flag for better error handling

echo "[SERVER] Current directory: \$(pwd)"
echo "[SERVER] Node version: \$(node --version 2>/dev/null || echo 'Not found')"
echo "[SERVER] NPM version: \$(npm --version 2>/dev/null || echo 'Not found')"
echo "[SERVER] Tar version: \$(tar --version 2>/dev/null | head -n1 || echo 'Not found')"

# Extract archive using tar (built-in shell command)
echo "[SERVER] Extracting archive from /tmp/$ARCHIVE_NAME..."
if [ ! -f "/tmp/$ARCHIVE_NAME" ]; then
    echo "[SERVER] ERROR: Archive file not found: /tmp/$ARCHIVE_NAME"
    exit 1
fi

# Create backup of current deployment if exists
if [ -d "$REMOTE_PATH" ] && [ "\$(ls -A $REMOTE_PATH 2>/dev/null)" ]; then
    echo "[SERVER] Creating backup of current deployment..."
    BACKUP_DIR="$REMOTE_PATH-backup-\$(date +%s)"
    mv "$REMOTE_PATH" "\$BACKUP_DIR" 2>/dev/null || true
    echo "[SERVER] Backup created at: \$BACKUP_DIR"
fi

# Create remote path directory
mkdir -p "$REMOTE_PATH" || exit 1
cd "$REMOTE_PATH" || exit 1

# Extract archive using tar
if ! tar -xzf "/tmp/$ARCHIVE_NAME" -C "$REMOTE_PATH" 2>/dev/null; then
    echo "[SERVER] ERROR: Failed to extract archive"
    exit 1
fi

echo "[SERVER] Archive extracted successfully"

# Cleanup archive file
rm -f "/tmp/$ARCHIVE_NAME" 2>/dev/null || echo "[SERVER] WARNING: Failed to cleanup archive (non-critical)"

# Install production dependencies only
if [ "$USE_YARN" = "y" ]; then
    echo "[SERVER] Installing production dependencies with Yarn..."
    if ! yarn install --production --ignore-engines --frozen-lockfile; then
        echo "[SERVER] ERROR: Failed to install dependencies with Yarn"
        exit 1
    fi
    START_COMMAND='yarn start --port 3000'
else
    echo "[SERVER] Installing production dependencies with npm..."
    if ! npm install --production --legacy-peer-deps --ignore-engines; then
        echo "[SERVER] ERROR: Failed to install dependencies with npm"
        exit 1
    fi
    START_COMMAND='npm run start'
fi

echo "[SERVER] Dependencies installed successfully"
echo "[SERVER] Note: Build was done locally, skipping build step on server"

# Manage PM2 process
echo "[SERVER] Managing PM2 process..."
if pm2 info next-app >/dev/null 2>&1; then
    echo "[SERVER] Stopping existing next-app process..."
    pm2 delete next-app || true
fi

echo "[SERVER] Starting application with PM2..."
if ! pm2 start bash --name next-app -- -lc "\$START_COMMAND"; then
    echo "[SERVER] ERROR: Failed to start application with PM2"
    exit 1
fi

echo "[SERVER] Saving PM2 configuration..."
if ! pm2 save; then
    echo "[SERVER] WARNING: Failed to save PM2 configuration (non-critical)"
fi

echo "[SERVER] PM2 status:"
pm2 status

echo "[SERVER] Deployment completed successfully!"
EOF

    local ssh_exit_code=$?
    if [ $ssh_exit_code -eq 0 ]; then
        log_info "Deployment completed successfully!"
        return 0
    else
        log_error "Deployment failed on server (exit code: $ssh_exit_code)"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting deployment process..."
    log_info "Server: $SERVER_USER@$SERVER_IP:$SERVER_PORT"
    log_info "Remote path: $REMOTE_PATH"
    log_info "Package manager: $([ "$USE_YARN" = "y" ] && echo 'Yarn' || echo 'npm')"
    
    local failed=0
    
    check_requirements || failed=1
    test_ssh_connection || failed=1
    if [ $failed -eq 1 ]; then
        error_exit "Critical requirements check failed"
    fi
    
    build_locally || failed=1
    if [ $failed -eq 1 ]; then
        error_exit "Failed to build locally"
    fi
    
    create_archive || failed=1
    if [ $failed -eq 1 ]; then
        error_exit "Failed to create archive"
    fi
    
    upload_archive || failed=1
    if [ $failed -eq 1 ]; then
        error_exit "Failed to upload archive"
    fi
    
    if ! deploy_on_server; then
        failed=1
    fi
    
    if [ $failed -eq 1 ]; then
        log_error "Deployment completed with errors. Please check the logs above."
        exit 1
    else
        log_info "All done! Application should be running on the server."
    fi
}

# Run main function
main
