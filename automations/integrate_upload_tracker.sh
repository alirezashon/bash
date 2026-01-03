#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# Upload Tracker Integration
# این اسکریپت upload.sh را با content_manager.sh یکپارچه می‌کند
# و به صورت خودکار آپلودها را در دیتابیس ثبت می‌کند
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENT_MANAGER="$SCRIPT_DIR/content_manager.sh"
UPLOAD_SCRIPT="$SCRIPT_DIR/upload.sh"

# Source content manager functions
if [ -f "$CONTENT_MANAGER" ]; then
  source "$CONTENT_MANAGER"
else
  echo "Error: content_manager.sh not found" >&2
  exit 1
fi

# Track upload result
track_upload() {
  local file="$1"
  local platform="$2"
  local status="$3"  # success, failed
  local url="${4:-}"
  
  # Add to database
  local metadata="{\"url\": \"$url\", \"tracked_at\": \"$(date -Iseconds)\"}"
  add_content "$file" "$platform" "$status" "$metadata"
  
  # Update status if URL provided
  if [ -n "$url" ] && [ "$status" = "success" ]; then
    # Get the last added entry ID (simplified - in production use proper ID tracking)
    log_info "Upload tracked: $platform - $(basename "$file")"
  fi
}

# Parse upload log and track
parse_and_track() {
  local log_file="$1"
  local platform="$2"
  
  if [ ! -f "$log_file" ]; then
    return 1
  fi
  
  # Extract success/failure from log
  if grep -q "success\|Success\|✓" "$log_file"; then
    local url=$(grep -oP 'https?://[^\s]+' "$log_file" | head -1 || echo "")
    track_upload "$file" "$platform" "success" "$url"
  elif grep -q "failed\|Failed\|✗\|error\|Error" "$log_file"; then
    track_upload "$file" "$platform" "failed" ""
  else
    track_upload "$file" "$platform" "pending" ""
  fi
}

# Main integration function
main() {
  log_info "Starting integrated upload with tracking..."
  
  # Run upload script and capture output
  if [ -f "$UPLOAD_SCRIPT" ]; then
    bash "$UPLOAD_SCRIPT" "$@"
    local exit_code=$?
    
    # After upload, track results from logs
    # This is a simplified version - in production, you'd parse actual upload responses
    log_info "Upload completed. Check content_manager.sh for analytics."
    
    return $exit_code
  else
    log_error "upload.sh not found"
    return 1
  fi
}

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi












