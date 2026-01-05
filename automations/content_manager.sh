#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# Content Management & Analytics System
# یک سیستم حرفه‌ای برای مدیریت، آنالیز و گزارش‌گیری از محتوا
# 
# Features:
# - 📊 Analytics Dashboard با گزارش‌های بصری
# - 📁 Metadata Management (مدیریت اطلاعات فایل‌ها)
# - 🔄 Auto Backup System
# - 📈 Performance Tracking
# - 🎯 Content Optimization Suggestions
# - 📋 Export Reports (JSON, CSV, HTML)
# - 🔍 Advanced Search & Filter
# - 📅 Scheduling & Automation
# ================================================================

# ==================== CONFIGURATION ====================
DB_DIR="${CONTENT_DB_DIR:-./content_db}"
DB_FILE="$DB_DIR/content_database.json"
BACKUP_DIR="${CONTENT_BACKUP_DIR:-./content_backups}"
REPORTS_DIR="${CONTENT_REPORTS_DIR:-./content_reports}"
METADATA_DIR="${CONTENT_METADATA_DIR:-./content_metadata}"
LOG_DIR="${CONTENT_LOG_DIR:-./content_logs}"

# Create directories
mkdir -p "$DB_DIR" "$BACKUP_DIR" "$REPORTS_DIR" "$METADATA_DIR" "$LOG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ==================== UTILITIES ====================
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }

# Initialize database if not exists
init_database() {
  if [ ! -f "$DB_FILE" ]; then
    echo '{"content": [], "stats": {"total_uploads": 0, "total_size": 0, "platforms": {}, "dates": {}}, "version": "1.0"}' > "$DB_FILE"
    log_info "Database initialized"
  fi
}

# Get file info
get_file_info() {
  local file="$1"
  if [ ! -f "$file" ]; then
    return 1
  fi
  
  local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
  local mime=$(file --brief --mime-type "$file" 2>/dev/null || echo "unknown")
  local modified=$(stat -f%m "$file" 2>/dev/null || stat -c%Y "$file" 2>/dev/null || date +%s)
  local duration=""
  
  # Get video duration if available
  if command -v ffprobe >/dev/null 2>&1 && [[ "$mime" == video/* ]]; then
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | cut -d. -f1 || echo "")
  fi
  
  # Get image dimensions if available
  local dimensions=""
  if [[ "$mime" == image/* ]] && command -v identify >/dev/null 2>&1; then
    dimensions=$(identify -format "%wx%h" "$file" 2>/dev/null || echo "")
  fi
  
  cat <<EOF
{
  "path": "$file",
  "name": "$(basename "$file")",
  "size": $size,
  "mime_type": "$mime",
  "modified": $modified,
  "duration": ${duration:-null},
  "dimensions": "${dimensions:-}"
}
EOF
}

# Add content to database
add_content() {
  local file="$1"
  local platform="$2"
  local status="$3"  # success, failed, pending
  local metadata="${4:-{}}"
  
  init_database
  
  local file_info=$(get_file_info "$file")
  local timestamp=$(date +%s)
  local date_str=$(date +%Y-%m-%d)
  
  local entry=$(cat <<EOF
{
  "id": "$(uuidgen 2>/dev/null || date +%s%N | sha256sum | cut -c1-16)",
  "file": $file_info,
  "platform": "$platform",
  "status": "$status",
  "timestamp": $timestamp,
  "date": "$date_str",
  "metadata": $metadata
}
EOF
)
  
  # Add to database using jq
  if command -v jq >/dev/null 2>&1; then
    local temp_file=$(mktemp)
    jq --argjson entry "$entry" '.content += [$entry] | .stats.total_uploads += 1 | .stats.total_size += ($entry.file.size // 0) | .stats.platforms[$entry.platform] = ((.stats.platforms[$entry.platform] // 0) + 1) | .stats.dates[$entry.date] = ((.stats.dates[$entry.date] // 0) + 1)' "$DB_FILE" > "$temp_file"
    mv "$temp_file" "$DB_FILE"
    log_success "Content added to database"
  else
    log_error "jq is required for database operations"
    return 1
  fi
}

# Update upload status
update_upload_status() {
  local id="$1"
  local status="$2"
  local url="${3:-}"
  
  if command -v jq >/dev/null 2>&1; then
    local temp_file=$(mktemp)
    if [ -n "$url" ]; then
      jq --arg id "$id" --arg status "$status" --arg url "$url" '(.content[] | select(.id == $id) | .status) = $status | (.content[] | select(.id == $id) | .url) = $url' "$DB_FILE" > "$temp_file"
    else
      jq --arg id "$id" --arg status "$status" '(.content[] | select(.id == $id) | .status) = $status' "$DB_FILE" > "$temp_file"
    fi
    mv "$temp_file" "$DB_FILE"
    log_success "Status updated"
  fi
}

# ==================== ANALYTICS & REPORTS ====================

# Generate statistics
generate_stats() {
  if [ ! -f "$DB_FILE" ] || ! command -v jq >/dev/null 2>&1; then
    log_error "Database or jq not available"
    return 1
  fi
  
  local total=$(jq '.stats.total_uploads' "$DB_FILE")
  local total_size=$(jq '.stats.total_size' "$DB_FILE")
  local platforms=$(jq -r '.stats.platforms | to_entries | .[] | "\(.key): \(.value)"' "$DB_FILE" 2>/dev/null || echo "")
  
  cat <<EOF
{
  "total_uploads": $total,
  "total_size_bytes": $total_size,
  "total_size_mb": $(echo "scale=2; $total_size / 1024 / 1024" | bc 2>/dev/null || echo "0"),
  "platforms": $(jq '.stats.platforms' "$DB_FILE"),
  "success_rate": $(calculate_success_rate),
  "top_platform": "$(get_top_platform)",
  "recent_uploads": $(get_recent_uploads 7)
}
EOF
}

# Calculate success rate
calculate_success_rate() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "0"
    return
  fi
  
  local total=$(jq '.content | length' "$DB_FILE")
  local success=$(jq '[.content[] | select(.status == "success")] | length' "$DB_FILE")
  
  if [ "$total" -eq 0 ]; then
    echo "0"
    return
  fi
  
  echo "scale=2; $success * 100 / $total" | bc 2>/dev/null || echo "0"
}

# Get top platform
get_top_platform() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "N/A"
    return
  fi
  
  jq -r '.stats.platforms | to_entries | sort_by(-.value) | .[0].key // "N/A"' "$DB_FILE" 2>/dev/null || echo "N/A"
}

# Get recent uploads
get_recent_uploads() {
  local days="${1:-7}"
  if ! command -v jq >/dev/null 2>&1; then
    echo "[]"
    return
  fi
  
  local cutoff=$(date -d "$days days ago" +%s 2>/dev/null || date -v-${days}d +%s 2>/dev/null || echo "0")
  jq --arg cutoff "$cutoff" '[.content[] | select(.timestamp >= ($cutoff | tonumber))] | length' "$DB_FILE" 2>/dev/null || echo "0"
}

# Format bytes to human readable
format_bytes() {
  local bytes="$1"
  local units=("B" "KB" "MB" "GB" "TB")
  local unit=0
  local size=$(echo "$bytes" | awk '{printf "%.2f", $1}')
  
  while (( $(echo "$size >= 1024" | bc -l 2>/dev/null || echo "0") )) && [ $unit -lt $((${#units[@]} - 1)) ]; do
    size=$(echo "scale=2; $size / 1024" | bc 2>/dev/null || echo "$size")
    unit=$((unit + 1))
  done
  
  echo "${size} ${units[$unit]}"
}

# Display dashboard
show_dashboard() {
  clear
  echo -e "${CYAN}"
  cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     📊 CONTENT MANAGEMENT & ANALYTICS DASHBOARD 📊        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
  echo -e "${NC}"
  
  if [ ! -f "$DB_FILE" ] || ! command -v jq >/dev/null 2>&1; then
    log_error "Database not initialized or jq not available"
    return 1
  fi
  
  local stats=$(generate_stats)
  local total=$(echo "$stats" | jq -r '.total_uploads')
  local total_size_mb=$(echo "$stats" | jq -r '.total_size_mb')
  local success_rate=$(echo "$stats" | jq -r '.success_rate')
  local top_platform=$(echo "$stats" | jq -r '.top_platform')
  local recent=$(echo "$stats" | jq -r '.recent_uploads')
  
  echo -e "${BOLD}📈 Overall Statistics${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "Total Uploads:     ${GREEN}$total${NC}"
  echo -e "Total Size:         ${BLUE}$(format_bytes $(echo "$stats" | jq -r '.total_size_bytes'))${NC}"
  echo -e "Success Rate:       ${GREEN}${success_rate}%${NC}"
  echo -e "Top Platform:       ${CYAN}$top_platform${NC}"
  echo -e "Recent (7 days):    ${YELLOW}$recent${NC}"
  echo ""
  
  # Platform breakdown
  echo -e "${BOLD}📱 Platform Distribution${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  local platforms=$(echo "$stats" | jq -r '.platforms | to_entries | .[] | "\(.key): \(.value)"')
  if [ -n "$platforms" ]; then
    while IFS= read -r line; do
      local platform=$(echo "$line" | cut -d: -f1 | xargs)
      local count=$(echo "$line" | cut -d: -f2 | xargs)
      local bar_length=$((count * 50 / total))
      local bar=$(printf "%${bar_length}s" | tr ' ' '█')
      printf "%-15s %5s ${GREEN}%s${NC}\n" "$platform" "$count" "$bar"
    done <<< "$platforms"
  else
    echo "No platform data available"
  fi
  echo ""
  
  # Recent activity
  echo -e "${BOLD}🕐 Recent Activity${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  show_recent_activity 10
  echo ""
  
  # File type distribution
  echo -e "${BOLD}📁 File Type Distribution${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  show_file_types
  echo ""
}

# Show recent activity
show_recent_activity() {
  local limit="${1:-10}"
  if ! command -v jq >/dev/null 2>&1; then
    return
  fi
  
  jq -r ".content | sort_by(-.timestamp) | .[0:$limit] | .[] | \"\(.date) | \(.platform) | \(.status) | \(.file.name)\"" "$DB_FILE" 2>/dev/null | while IFS='|' read -r date platform status name; do
    local status_color="$GREEN"
    [ "$status" = "failed" ] && status_color="$RED"
    [ "$status" = "pending" ] && status_color="$YELLOW"
    printf "%-12s %-12s ${status_color}%-8s${NC} %s\n" "$date" "$platform" "$status" "$name"
  done
}

# Show file types
show_file_types() {
  if ! command -v jq >/dev/null 2>&1; then
    return
  fi
  
  jq -r '.content[].file.mime_type' "$DB_FILE" 2>/dev/null | sort | uniq -c | sort -rn | while read count mime; do
    local type=$(echo "$mime" | cut -d/ -f1)
    local subtype=$(echo "$mime" | cut -d/ -f2)
    printf "%-10s %-20s ${CYAN}%s${NC}\n" "$count" "$type" "$subtype"
  done
}

# ==================== SEARCH & FILTER ====================

# Search content
search_content() {
  local query="$1"
  local field="${2:-name}"
  
  if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is required"
    return 1
  fi
  
  case "$field" in
    "name")
      jq -r ".content[] | select(.file.name | contains(\"$query\")) | \"\(.id) | \(.file.name) | \(.platform) | \(.status)\"" "$DB_FILE"
      ;;
    "platform")
      jq -r ".content[] | select(.platform == \"$query\") | \"\(.id) | \(.file.name) | \(.platform) | \(.status)\"" "$DB_FILE"
      ;;
    "status")
      jq -r ".content[] | select(.status == \"$query\") | \"\(.id) | \(.file.name) | \(.platform) | \(.status)\"" "$DB_FILE"
      ;;
    "date")
      jq -r ".content[] | select(.date == \"$query\") | \"\(.id) | \(.file.name) | \(.platform) | \(.status)\"" "$DB_FILE"
      ;;
    *)
      jq -r ".content[] | select(.file.name | contains(\"$query\")) | \"\(.id) | \(.file.name) | \(.platform) | \(.status)\"" "$DB_FILE"
      ;;
  esac
}

# Filter by date range
filter_by_date_range() {
  local start_date="$1"
  local end_date="$2"
  
  if ! command -v jq >/dev/null 2>&1; then
    return 1
  fi
  
  jq -r --arg start "$start_date" --arg end "$end_date" \
    ".content[] | select(.date >= \$start and .date <= \$end) | \"\(.date) | \(.file.name) | \(.platform) | \(.status)\"" "$DB_FILE"
}

# ==================== EXPORT REPORTS ====================

# Export to JSON
export_json() {
  local output="$REPORTS_DIR/report_$(date +%Y%m%d_%H%M%S).json"
  cp "$DB_FILE" "$output"
  log_success "Exported to: $output"
  echo "$output"
}

# Export to CSV
export_csv() {
  local output="$REPORTS_DIR/report_$(date +%Y%m%d_%H%M%S).csv"
  
  if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is required"
    return 1
  fi
  
  # CSV header
  echo "ID,Date,Platform,Status,File Name,Size (bytes),MIME Type" > "$output"
  
  # CSV data
  jq -r '.content[] | "\(.id),\(.date),\(.platform),\(.status),\(.file.name),\(.file.size),\(.file.mime_type)"' "$DB_FILE" >> "$output"
  
  log_success "Exported to: $output"
  echo "$output"
}

# Export to HTML
export_html() {
  local output="$REPORTS_DIR/report_$(date +%Y%m%d_%H%M%S).html"
  
  if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is required"
    return 1
  fi
  
  local stats=$(generate_stats)
  local total=$(echo "$stats" | jq -r '.total_uploads')
  local success_rate=$(echo "$stats" | jq -r '.success_rate')
  
  cat > "$output" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Content Analytics Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
        .stat-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; text-align: center; }
        .stat-value { font-size: 2em; font-weight: bold; }
        .stat-label { margin-top: 5px; opacity: 0.9; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; }
        tr:hover { background-color: #f5f5f5; }
        .status-success { color: #4CAF50; font-weight: bold; }
        .status-failed { color: #f44336; font-weight: bold; }
        .status-pending { color: #ff9800; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Content Analytics Report</h1>
        <p>Generated: $(date)</p>
        
        <div class="stats">
            <div class="stat-card">
                <div class="stat-value">$total</div>
                <div class="stat-label">Total Uploads</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${success_rate}%</div>
                <div class="stat-label">Success Rate</div>
            </div>
        </div>
        
        <h2>Upload History</h2>
        <table>
            <thead>
                <tr>
                    <th>Date</th>
                    <th>Platform</th>
                    <th>Status</th>
                    <th>File Name</th>
                    <th>Size</th>
                </tr>
            </thead>
            <tbody>
EOF

  jq -r '.content[] | "<tr><td>\(.date)</td><td>\(.platform)</td><td class=\"status-\(.status)\">\(.status)</td><td>\(.file.name)</td><td>\(.file.size)</td></tr>"' "$DB_FILE" >> "$output"
  
  cat >> "$output" <<EOF
            </tbody>
        </table>
    </div>
</body>
</html>
EOF

  log_success "Exported to: $output"
  echo "$output"
}

# ==================== BACKUP SYSTEM ====================

# Create backup
create_backup() {
  local backup_file="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
  
  mkdir -p "$BACKUP_DIR"
  
  tar -czf "$backup_file" "$DB_DIR" "$METADATA_DIR" 2>/dev/null || {
    log_error "Backup failed"
    return 1
  }
  
  log_success "Backup created: $backup_file"
  echo "$backup_file"
}

# Restore backup
restore_backup() {
  local backup_file="$1"
  
  if [ ! -f "$backup_file" ]; then
    log_error "Backup file not found: $backup_file"
    return 1
  fi
  
  log_warn "This will overwrite current database. Continue? (y/N)"
  read -r confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    return
  fi
  
  tar -xzf "$backup_file" -C "$(dirname "$DB_DIR")" 2>/dev/null || {
    log_error "Restore failed"
    return 1
  }
  
  log_success "Backup restored"
}

# List backups
list_backups() {
  if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    log_warn "No backups found"
    return
  fi
  
  echo -e "${CYAN}Available Backups:${NC}"
  ls -lht "$BACKUP_DIR" | grep -v "^total" | awk '{print $9, $5, $6, $7, $8}' | head -10
}

# ==================== OPTIMIZATION SUGGESTIONS ====================

# Get optimization suggestions
get_optimization_suggestions() {
  if ! command -v jq >/dev/null 2>&1; then
    return
  fi
  
  echo -e "${BOLD}💡 Optimization Suggestions${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Check success rate
  local success_rate=$(calculate_success_rate)
  if (( $(echo "$success_rate < 80" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "${YELLOW}⚠${NC}  Low success rate ($success_rate%). Check failed uploads."
  fi
  
  # Check platform distribution
  local platform_count=$(jq '.stats.platforms | length' "$DB_FILE" 2>/dev/null || echo "0")
  if [ "$platform_count" -lt 2 ]; then
    echo -e "${YELLOW}⚠${NC}  Consider diversifying platforms for better reach."
  fi
  
  # Check file sizes
  local avg_size=$(jq '[.content[].file.size] | add / length' "$DB_FILE" 2>/dev/null || echo "0")
  local avg_size_mb=$(echo "scale=2; $avg_size / 1024 / 1024" | bc 2>/dev/null || echo "0")
  
  if (( $(echo "$avg_size_mb > 100" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "${YELLOW}⚠${NC}  Large average file size (${avg_size_mb}MB). Consider compression."
  fi
  
  # Recent activity check
  local recent=$(get_recent_uploads 7)
  if [ "$recent" -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC}  No uploads in the last 7 days. Consider scheduling regular uploads."
  fi
  
  echo ""
}

# ==================== MAIN MENU ====================
main_menu() {
  while true; do
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     📊 CONTENT MANAGEMENT & ANALYTICS SYSTEM 📊          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo "1) 📊 View Dashboard"
    echo "2) ➕ Add Content Entry"
    echo "3) 🔍 Search Content"
    echo "4) 📅 Filter by Date Range"
    echo "5) 📤 Export Reports (JSON/CSV/HTML)"
    echo "6) 💾 Backup Database"
    echo "7) 📥 Restore Backup"
    echo "8) 💡 Optimization Suggestions"
    echo "9) 🗑️  Clean Old Data"
    echo "10) ⚙️  Settings"
    echo "11) ❌ Exit"
    echo ""
    read -p "Select option: " choice
    
    case "$choice" in
      1)
        show_dashboard
        read -p "Press Enter to continue..."
        ;;
      2)
        add_content_interactive
        ;;
      3)
        search_content_interactive
        ;;
      4)
        filter_by_date_interactive
        ;;
      5)
        export_reports_menu
        ;;
      6)
        create_backup
        read -p "Press Enter to continue..."
        ;;
      7)
        restore_backup_interactive
        ;;
      8)
        get_optimization_suggestions
        read -p "Press Enter to continue..."
        ;;
      9)
        clean_old_data
        ;;
      10)
        settings_menu
        ;;
      11)
        log_info "Goodbye!"
        exit 0
        ;;
      *)
        log_error "Invalid option"
        sleep 1
        ;;
    esac
  done
}

# Interactive functions
add_content_interactive() {
  read -p "Enter file path: " file_path
  if [ ! -f "$file_path" ]; then
    log_error "File not found: $file_path"
    read -p "Press Enter to continue..."
    return
  fi
  
  echo "Select platform:"
  select platform in "YouTube" "Telegram" "Discord" "Instagram" "X" "Reddit" "Other"; do
    [ -n "$platform" ] && break
  done
  
  echo "Select status:"
  select status in "success" "failed" "pending"; do
    [ -n "$status" ] && break
  done
  
  read -p "Enter metadata (JSON, optional): " metadata
  metadata="${metadata:-{}}"
  
  add_content "$file_path" "$platform" "$status" "$metadata"
  read -p "Press Enter to continue..."
}

search_content_interactive() {
  read -p "Enter search query: " query
  echo "Search by:"
  select field in "name" "platform" "status" "date"; do
    [ -n "$field" ] && break
  done
  
  echo -e "${CYAN}Search Results:${NC}"
  search_content "$query" "$field" | while IFS='|' read -r id name platform status; do
    printf "%-20s %-15s %-10s %s\n" "$id" "$name" "$platform" "$status"
  done
  read -p "Press Enter to continue..."
}

filter_by_date_interactive() {
  read -p "Enter start date (YYYY-MM-DD): " start_date
  read -p "Enter end date (YYYY-MM-DD): " end_date
  
  echo -e "${CYAN}Filtered Results:${NC}"
  filter_by_date_range "$start_date" "$end_date" | while IFS='|' read -r date name platform status; do
    printf "%-12s %-30s %-15s %s\n" "$date" "$name" "$platform" "$status"
  done
  read -p "Press Enter to continue..."
}

export_reports_menu() {
  echo "Export format:"
  select format in "JSON" "CSV" "HTML" "All"; do
    case "$format" in
      "JSON")
        export_json
        ;;
      "CSV")
        export_csv
        ;;
      "HTML")
        export_html
        ;;
      "All")
        export_json
        export_csv
        export_html
        ;;
    esac
    break
  done
  read -p "Press Enter to continue..."
}

restore_backup_interactive() {
  list_backups
  echo ""
  read -p "Enter backup filename: " backup_name
  if [ -n "$backup_name" ]; then
    restore_backup "$BACKUP_DIR/$backup_name"
  fi
  read -p "Press Enter to continue..."
}

clean_old_data() {
  read -p "Delete entries older than (days): " days
  if [[ ! "$days" =~ ^[0-9]+$ ]]; then
    log_error "Invalid number"
    read -p "Press Enter to continue..."
    return
  fi
  
  local cutoff=$(date -d "$days days ago" +%s 2>/dev/null || date -v-${days}d +%s 2>/dev/null || echo "0")
  
  if command -v jq >/dev/null 2>&1; then
    local temp_file=$(mktemp)
    jq --arg cutoff "$cutoff" '.content = [.content[] | select(.timestamp >= ($cutoff | tonumber))]' "$DB_FILE" > "$temp_file"
    mv "$temp_file" "$DB_FILE"
    log_success "Old data cleaned"
  fi
  read -p "Press Enter to continue..."
}

settings_menu() {
  clear
  echo -e "${CYAN}=== Settings ===${NC}"
  echo "1) Database directory: $DB_DIR"
  echo "2) Backup directory: $BACKUP_DIR"
  echo "3) Reports directory: $REPORTS_DIR"
  echo "4) Back"
  read -p "Select option: " choice
  # Settings can be extended
  read -p "Press Enter to continue..."
}

# ==================== INITIALIZATION ====================
init_database

# Check if running interactively
if [ -t 0 ]; then
  main_menu
else
  # Non-interactive mode
  log_info "Content Manager - Use with upload.sh for automatic tracking"
  log_info "Run interactively for full features"
fi














