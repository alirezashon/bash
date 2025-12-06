#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# Advanced Multi-Platform Upload Script
# Features:
# - Interactive menu system with multi-select
# - Support for carousel posts (multiple images like Instagram)
# - Image resize templates
# - Better API error handling
# - Platform-specific optimizations
# ================================================================

# ==================== CONFIGURATION ====================
# Load config from environment or use defaults
SOURCE_DIR="${UPLOAD_SOURCE_DIR:-./to_upload}"
MAX_CONCURRENT_JOBS="${UPLOAD_MAX_CONCURRENT:-4}"
LOG_DIR="${UPLOAD_LOG_DIR:-./upload_logs}"
CONFIG_FILE="${UPLOAD_CONFIG_FILE:-./upload_config.env}"

# Load config file if exists
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

# YouTube (Google APIs) - OAuth 2.0
YOUTUBE_ACCESS_TOKEN="${YOUTUBE_ACCESS_TOKEN:-}"
YOUTUBE_CHANNEL_ID="${YOUTUBE_CHANNEL_ID:-}"
YOUTUBE_PRIVACY="${YOUTUBE_PRIVACY:-public}"  # public, unlisted, private

# Telegram
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

# Instagram Graph API (Business/Creator)
IG_ACCESS_TOKEN="${IG_ACCESS_TOKEN:-}"
IG_INSTAGRAM_ACCOUNT_ID="${IG_INSTAGRAM_ACCOUNT_ID:-}"
IG_APP_SECRET="${IG_APP_SECRET:-}"

# Discord
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"

# X (Twitter) - OAuth 1.0a
X_CONSUMER_KEY="${X_CONSUMER_KEY:-}"
X_CONSUMER_SECRET="${X_CONSUMER_SECRET:-}"
X_ACCESS_TOKEN="${X_ACCESS_TOKEN:-}"
X_ACCESS_TOKEN_SECRET="${X_ACCESS_TOKEN_SECRET:-}"

# Reddit
REDDIT_ACCESS_TOKEN="${REDDIT_ACCESS_TOKEN:-}"
REDDIT_SUBREDDIT="${REDDIT_SUBREDDIT:-}"

# Image resize templates (width x height)
declare -A SIZE_TEMPLATES=(
  ["square"]="1080x1080"
  ["story"]="1080x1920"
  ["post"]="1080x1350"
  ["landscape"]="1920x1080"
  ["portrait"]="1080x1350"
  ["original"]="original"
)

mkdir -p "$LOG_DIR"

# ==================== UTILITIES ====================
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${CYAN}[DEBUG]${NC} $1"; }

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check required tools
check_requirements() {
  local missing=()
  command_exists curl || missing+=("curl")
  command_exists jq || missing+=("jq")
  command_exists file || missing+=("file")
  
  if [ "${#missing[@]}" -gt 0 ]; then
    log_error "Missing required tools: ${missing[*]}"
    log_info "Please install: ${missing[*]}"
    exit 1
  fi
  
  # Optional tools
  if command_exists magick || command_exists convert; then
    HAS_IMAGEMAGICK=true
  else
    HAS_IMAGEMAGICK=false
    log_warn "ImageMagick not found. Image resizing will be disabled."
  fi
}

# Resize image using ImageMagick
resize_image() {
  local input="$1"
  local output="$2"
  local size="$3"
  
  if [ "$size" = "original" ]; then
    cp "$input" "$output"
    return 0
  fi
  
  if [ "$HAS_IMAGEMAGICK" = false ]; then
    log_warn "Cannot resize: ImageMagick not available"
    cp "$input" "$output"
    return 0
  fi
  
  local width="${size%%x*}"
  local height="${size##*x}"
  
  if command_exists magick; then
    magick "$input" -resize "${width}x${height}^" -gravity center -extent "${width}x${height}" "$output" 2>/dev/null
  elif command_exists convert; then
    convert "$input" -resize "${width}x${height}^" -gravity center -extent "${width}x${height}" "$output" 2>/dev/null
  else
    cp "$input" "$output"
    return 1
  fi
}

# Get file mime type
get_mime_type() {
  file --brief --mime-type "$1" 2>/dev/null || echo "application/octet-stream"
}

# Check if file is image
is_image() {
  local mime=$(get_mime_type "$1")
  [[ "$mime" =~ ^image/ ]]
}

# Check if file is video
is_video() {
  local mime=$(get_mime_type "$1")
  [[ "$mime" =~ ^video/ ]]
}

# ==================== INTERACTIVE MENU ====================
# Multi-select menu
multi_select_menu() {
  local title="$1"
  shift
  local options=("$@")
  local selected=()
  local current_index=0
  
  while true; do
    clear
    echo -e "${CYAN}=== $title ===${NC}"
    echo ""
    
    for i in "${!options[@]}"; do
      local marker=" "
      if [[ " ${selected[@]} " =~ " $i " ]]; then
        marker="[X]"
      else
        marker="[ ]"
      fi
      
      if [ $i -eq $current_index ]; then
        echo -e "${GREEN}>${NC} $marker ${options[$i]}"
      else
        echo "  $marker ${options[$i]}"
      fi
    done
    
    echo ""
    echo -e "${YELLOW}Use:${NC} Space=Toggle, Enter=Done, Q=Quit"
    
    read -rsn1 key
    
    case "$key" in
      "q"|"Q")
        return 1
        ;;
      " ")
        if [[ " ${selected[@]} " =~ " $current_index " ]]; then
          selected=("${selected[@]/$current_index}")
          selected=($(printf '%s\n' "${selected[@]}" | grep -v "^$"))
        else
          selected+=($current_index)
        fi
        ;;
      "")
        if [ "${#selected[@]}" -gt 0 ]; then
          printf '%s\n' "${selected[@]}"
          return 0
        else
          log_warn "Please select at least one option"
          sleep 1
        fi
        ;;
      $'\x1b')  # ESC sequence
        read -rsn1 -t 0.1 tmp
        if [[ "$tmp" == "[" ]]; then
          read -rsn1 -t 0.1 tmp
          case "$tmp" in
            "A")  # Up arrow
              current_index=$(( (current_index - 1 + ${#options[@]}) % ${#options[@]} ))
              ;;
            "B")  # Down arrow
              current_index=$(( (current_index + 1) % ${#options[@]} ))
              ;;
          esac
        fi
        ;;
    esac
  done
}

# Simple select menu
select_menu() {
  local title="$1"
  shift
  local options=("$@")
  
  echo -e "${CYAN}=== $title ===${NC}"
  select opt in "${options[@]}" "Back"; do
    if [ "$opt" = "Back" ]; then
      return 1
    fi
    if [ -n "$opt" ]; then
      echo "$REPLY"
      return 0
    fi
  done
}

# Select files
select_files() {
  local files=("$@")
  if [ "${#files[@]}" -eq 0 ]; then
    log_error "No files found"
    return 1
  fi
  
  local titles=()
  for f in "${files[@]}"; do
    local name=$(basename "$f")
    local size=$(du -h "$f" | cut -f1)
    local type=""
    if is_image "$f"; then
      type="📷 Image"
    elif is_video "$f"; then
      type="🎥 Video"
    else
      type="📄 File"
    fi
    titles+=("$name ($size) - $type")
  done
  
  multi_select_menu "Select Files to Upload" "${titles[@]}" | while read idx; do
    echo "${files[$idx]}"
  done
}

# ==================== CONCURRENCY CONTROL ====================
JOB_COUNT=0
declare -a jobs_pids=()

run_job() {
  local cmd="$*"
  bash -c "$cmd" &
  local pid=$!
  jobs_pids+=($pid)
  JOB_COUNT=$((JOB_COUNT + 1))
  
  while [ "$JOB_COUNT" -ge "$MAX_CONCURRENT_JOBS" ]; do
    if wait -n 2>/dev/null; then
      JOB_COUNT=$((JOB_COUNT - 1))
      # Remove finished pid
      local new_pids=()
      for p in "${jobs_pids[@]}"; do
        if kill -0 "$p" 2>/dev/null; then
          new_pids+=($p)
        fi
      done
      jobs_pids=("${new_pids[@]}")
    else
      sleep 0.1
    fi
  done
}

# ==================== UPLOAD FUNCTIONS ====================

# YouTube upload
upload_youtube() {
  local file="$1"
  local title="$2"
  local description="$3"
  local logfile="$LOG_DIR/youtube_$(basename "$file" | tr ' ' '_').log"
  
  if [ -z "$YOUTUBE_ACCESS_TOKEN" ]; then
    log_error "YouTube access token not configured"
    return 1
  fi
  
  if ! is_video "$file"; then
    log_error "YouTube only supports video uploads: $file"
    return 1
  fi
  
  log_info "Uploading to YouTube: $(basename "$file")"
  echo "[$(date)] Starting YouTube upload: $file" > "$logfile"
  
  local resp
  resp=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
    -H "Accept: application/json" \
    -F "snippet={\"title\":\"$title\",\"description\":\"$description\",\"categoryId\":\"22\"};type=application/json; charset=UTF-8" \
    -F "status={\"privacyStatus\":\"$YOUTUBE_PRIVACY\"};type=application/json; charset=UTF-8" \
    -F "media=@\"$file\";type=$(get_mime_type "$file")" \
    "https://www.googleapis.com/upload/youtube/v3/videos?uploadType=multipart&part=snippet,status" 2>&1)
  
  local http_code=$(echo "$resp" | tail -n1)
  local body=$(echo "$resp" | sed '$d')
  
  echo "$body" >> "$logfile"
  
  if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
    if echo "$body" | jq -e '.id' >/dev/null 2>&1; then
      local video_id=$(echo "$body" | jq -r '.id')
      log_info "✓ YouTube upload success: https://youtube.com/watch?v=$video_id"
      echo "[$(date)] Success: Video ID $video_id" >> "$logfile"
      return 0
    fi
  fi
  
  log_error "YouTube upload failed (HTTP $http_code)"
  echo "[$(date)] Failed: $body" >> "$logfile"
  return 1
}

# Telegram upload (single or album)
upload_telegram() {
  local files=("$@")
  local caption="${files[-1]}"
  unset 'files[-1]'
  
  if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    log_error "Telegram credentials not configured"
    return 1
  fi
  
  local logfile="$LOG_DIR/telegram_$(date +%s).log"
  log_info "Uploading ${#files[@]} file(s) to Telegram"
  
  # Single file
  if [ "${#files[@]}" -eq 1 ]; then
    local file="${files[0]}"
    local mime=$(get_mime_type "$file")
    local method=""
    local field_name=""
    
    if is_video "$file"; then
      method="sendVideo"
      field_name="video"
    elif is_image "$file"; then
      method="sendPhoto"
      field_name="photo"
    else
      method="sendDocument"
      field_name="document"
    fi
    
    local resp
    resp=$(curl -s -w "\n%{http_code}" -X POST \
      "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/${method}" \
      -F "chat_id=${TELEGRAM_CHAT_ID}" \
      -F "${field_name}=@${file}" \
      -F "caption=${caption}" 2>&1)
    
    local http_code=$(echo "$resp" | tail -n1)
    local body=$(echo "$resp" | sed '$d')
    
    echo "$body" >> "$logfile"
    
    if [ "$http_code" -eq 200 ]; then
      if echo "$body" | jq -e '.ok == true' >/dev/null 2>&1; then
        log_info "✓ Telegram upload success"
        return 0
      fi
    fi
    log_error "Telegram upload failed"
    return 1
  fi
  
  # Multiple files (as album)
  if [ "${#files[@]}" -gt 1 ] && [ "${#files[@]}" -le 10 ]; then
    # Check if all are images
    local all_images=true
    for f in "${files[@]}"; do
      if ! is_image "$f"; then
        all_images=false
        break
      fi
    done
    
    if [ "$all_images" = true ]; then
      # Send as photo album
      local media_json="["
      for i in "${!files[@]}"; do
        if [ $i -gt 0 ]; then
          media_json+=","
        fi
        media_json+="{\"type\":\"photo\",\"media\":\"attach://photo$i\"}"
      done
      media_json+="]"
      
      local curl_args=()
      curl_args+=(-X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMediaGroup")
      curl_args+=(-F "chat_id=${TELEGRAM_CHAT_ID}")
      curl_args+=(-F "media=$media_json")
      curl_args+=(-F "caption=$caption")
      
      for i in "${!files[@]}"; do
        curl_args+=(-F "photo$i=@${files[$i]}")
      done
      
      local resp
      resp=$(curl -s -w "\n%{http_code}" "${curl_args[@]}" 2>&1)
      
      local http_code=$(echo "$resp" | tail -n1)
      local body=$(echo "$resp" | sed '$d')
      
      echo "$body" >> "$logfile"
      
      if [ "$http_code" -eq 200 ]; then
        if echo "$body" | jq -e '.ok == true' >/dev/null 2>&1; then
          log_info "✓ Telegram album upload success"
          return 0
        fi
      fi
      log_error "Telegram album upload failed"
      return 1
    fi
  fi
  
  # Fallback: send files separately
  for file in "${files[@]}"; do
    upload_telegram "$file" "$caption"
  done
}

# Discord upload
upload_discord() {
  local files=("$@")
  local content="${files[-1]}"
  unset 'files[-1]'
  
  if [ -z "$DISCORD_WEBHOOK_URL" ]; then
    log_error "Discord webhook URL not configured"
    return 1
  fi
  
  local logfile="$LOG_DIR/discord_$(date +%s).log"
  log_info "Uploading ${#files[@]} file(s) to Discord"
  
  for file in "${files[@]}"; do
    local resp
    resp=$(curl -s -w "\n%{http_code}" -X POST "$DISCORD_WEBHOOK_URL" \
      -F "content=$content" \
      -F "file=@${file}" 2>&1)
    
    local http_code=$(echo "$resp" | tail -n1)
    local body=$(echo "$resp" | sed '$d')
    
    echo "$body" >> "$logfile"
    
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 204 ]; then
      log_info "✓ Discord upload success: $(basename "$file")"
    else
      log_error "Discord upload failed for: $(basename "$file")"
    fi
  done
}

# Instagram upload (single image/video or carousel)
upload_instagram() {
  local files=("$@")
  local caption="${files[-1]}"
  unset 'files[-1]'
  
  if [ -z "$IG_ACCESS_TOKEN" ] || [ -z "$IG_INSTAGRAM_ACCOUNT_ID" ]; then
    log_error "Instagram credentials not configured"
    return 1
  fi
  
  local logfile="$LOG_DIR/instagram_$(date +%s).log"
  log_info "Uploading ${#files[@]} file(s) to Instagram"
  
  # Single image
  if [ "${#files[@]}" -eq 1 ] && is_image "${files[0]}"; then
    local file="${files[0]}"
    
    # Step 1: Upload image to temporary hosting (Instagram requires public URL)
    # For local files, you need to host them somewhere first
    # This is a placeholder - in production, upload to S3/CDN first
    log_warn "Instagram Graph API requires publicly accessible URLs"
    log_warn "Please upload files to a hosting service first (S3, CDN, etc.)"
    echo "[$(date)] Instagram upload skipped - requires public URLs" >> "$logfile"
    return 1
    
    # Placeholder for actual implementation:
    # local image_url="https://your-cdn.com/image.jpg"
    # local create_resp=$(curl -s -X POST \
    #   "https://graph.facebook.com/v18.0/${IG_INSTAGRAM_ACCOUNT_ID}/media" \
    #   -F "access_token=${IG_ACCESS_TOKEN}" \
    #   -F "image_url=${image_url}" \
    #   -F "caption=${caption}")
    # local creation_id=$(echo "$create_resp" | jq -r '.id')
    # Then publish: curl -X POST \
    #   "https://graph.facebook.com/v18.0/${IG_INSTAGRAM_ACCOUNT_ID}/media_publish" \
    #   -F "access_token=${IG_ACCESS_TOKEN}" \
    #   -F "creation_id=${creation_id}"
  fi
  
  # Carousel (multiple images)
  if [ "${#files[@]}" -gt 1 ] && [ "${#files[@]}" -le 10 ]; then
    log_warn "Instagram carousel requires public URLs for each image"
    log_warn "Please implement URL hosting for carousel posts"
    echo "[$(date)] Instagram carousel skipped - requires public URLs" >> "$logfile"
    return 1
  fi
  
  return 1
}

# X (Twitter) upload
upload_x() {
  local files=("$@")
  local status="${files[-1]}"
  unset 'files[-1]'
  
  if [ -z "$X_CONSUMER_KEY" ] || [ -z "$X_ACCESS_TOKEN" ]; then
    log_error "X (Twitter) credentials not configured"
    return 1
  fi
  
  local logfile="$LOG_DIR/x_$(date +%s).log"
  log_info "Uploading to X (Twitter): ${#files[@]} file(s)"
  log_warn "X API requires OAuth 1.0a signature - implementation needed"
  echo "[$(date)] X upload placeholder" >> "$logfile"
  return 1
}

# Reddit upload
upload_reddit() {
  local files=("$@")
  local title="${files[-1]}"
  unset 'files[-1]'
  
  if [ -z "$REDDIT_ACCESS_TOKEN" ] || [ -z "$REDDIT_SUBREDDIT" ]; then
    log_error "Reddit credentials not configured"
    return 1
  fi
  
  local logfile="$LOG_DIR/reddit_$(date +%s).log"
  log_info "Uploading to Reddit: ${#files[@]} file(s)"
  log_warn "Reddit API requires multi-step media upload - implementation needed"
  echo "[$(date)] Reddit upload placeholder" >> "$logfile"
  return 1
}

# ==================== MAIN MENU ====================
main_menu() {
  while true; do
    clear
    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Multi-Platform Upload Manager      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
    echo ""
    echo "1) Select files and upload"
    echo "2) Upload all files in directory"
    echo "3) Configure settings"
    echo "4) View logs"
    echo "5) Exit"
    echo ""
    read -p "Select option: " choice
    
    case "$choice" in
      1)
        upload_selected_files
        ;;
      2)
        upload_all_files
        ;;
      3)
        configure_settings
        ;;
      4)
        view_logs
        ;;
      5)
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

# Upload selected files
upload_selected_files() {
  if [ ! -d "$SOURCE_DIR" ]; then
    log_error "Source directory does not exist: $SOURCE_DIR"
    read -p "Press Enter to continue..."
    return
  fi
  
  # Find all media files
  local all_files=()
  while IFS= read -r -d '' file; do
    all_files+=("$file")
  done < <(find "$SOURCE_DIR" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.webm" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) -print0)
  
  if [ "${#all_files[@]}" -eq 0 ]; then
    log_error "No media files found in $SOURCE_DIR"
    read -p "Press Enter to continue..."
    return
  fi
  
  # Select files
  local selected_files=($(select_files "${all_files[@]}"))
  if [ "${#selected_files[@]}" -eq 0 ]; then
    log_warn "No files selected"
    read -p "Press Enter to continue..."
    return
  fi
  
  # Select platforms
  local platforms=("YouTube" "Telegram" "Discord" "Instagram" "X (Twitter)" "Reddit")
  local selected_platforms=($(multi_select_menu "Select Platforms" "${platforms[@]}" | sort -n))
  
  if [ "${#selected_platforms[@]}" -eq 0 ]; then
    log_warn "No platforms selected"
    read -p "Press Enter to continue..."
    return
  fi
  
  # Get metadata
  read -p "Enter title/caption: " title
  title="${title:-$(basename "${selected_files[0]}" | sed 's/\.[^.]*$//')}"
  read -p "Enter description (optional): " description
  description="${description:-Uploaded via multi_upload.sh}"
  
  # Image resize option
  local resize_template="original"
  if [ "${#selected_files[@]}" -gt 0 ]; then
    local first_file="${selected_files[0]}"
    if is_image "$first_file"; then
      local size_options=("original" "square" "story" "post" "landscape" "portrait")
      local size_choice=$(select_menu "Select Image Size Template" "${size_options[@]}")
      if [ -n "$size_choice" ] && [ "$size_choice" != "Back" ]; then
        resize_template="${size_options[$((size_choice-1))]}"
      fi
    fi
  fi
  
  # Process files with resize if needed
  local processed_files=("${selected_files[@]}")
  if [ "$resize_template" != "original" ] && [ "$HAS_IMAGEMAGICK" = true ]; then
    log_info "Resizing images to template: $resize_template"
    local temp_dir=$(mktemp -d)
    local new_files=()
    for file in "${selected_files[@]}"; do
      if is_image "$file"; then
        local output="$temp_dir/$(basename "$file")"
        resize_image "$file" "$output" "${SIZE_TEMPLATES[$resize_template]}"
        new_files+=("$output")
      else
        new_files+=("$file")
      fi
    done
    processed_files=("${new_files[@]}")
  fi
  
  # Upload to selected platforms
  for platform_idx in "${selected_platforms[@]}"; do
    local platform="${platforms[$platform_idx]}"
    
    case "$platform" in
      "YouTube")
        for file in "${processed_files[@]}"; do
          if is_video "$file"; then
            run_job "upload_youtube \"$file\" \"$title\" \"$description\""
          fi
        done
        ;;
      "Telegram")
        local telegram_files=("${processed_files[@]}")
        telegram_files+=("$description")
        run_job "upload_telegram ${telegram_files[*]}"
        ;;
      "Discord")
        local discord_files=("${processed_files[@]}")
        discord_files+=("$description")
        run_job "upload_discord ${discord_files[*]}"
        ;;
      "Instagram")
        local ig_files=("${processed_files[@]}")
        ig_files+=("$description")
        run_job "upload_instagram ${ig_files[*]}"
        ;;
      "X (Twitter)")
        local x_files=("${processed_files[@]}")
        x_files+=("$description")
        run_job "upload_x ${x_files[*]}"
        ;;
      "Reddit")
        local reddit_files=("${processed_files[@]}")
        reddit_files+=("$title")
        run_job "upload_reddit ${reddit_files[*]}"
        ;;
    esac
  done
  
  # Wait for all jobs
  wait
  log_info "All upload jobs completed!"
  
  # Cleanup temp files
  if [ -n "${temp_dir:-}" ] && [ -d "$temp_dir" ]; then
    rm -rf "$temp_dir"
  fi
  
  read -p "Press Enter to continue..."
}

# Upload all files
upload_all_files() {
  log_info "This will upload ALL files in $SOURCE_DIR"
  read -p "Are you sure? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    return
  fi
  
  # Find all files
  local all_files=()
  while IFS= read -r -d '' file; do
    all_files+=("$file")
  done < <(find "$SOURCE_DIR" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.webm" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) -print0)
  
  if [ "${#all_files[@]}" -eq 0 ]; then
    log_error "No files found"
    read -p "Press Enter to continue..."
    return
  fi
  
  # Select platforms
  local platforms=("YouTube" "Telegram" "Discord" "Instagram" "X" "Reddit")
  local selected_platforms=($(multi_select_menu "Select Platforms" "${platforms[@]}" | sort -n))
  
  # Process each file
  for file in "${all_files[@]}"; do
    local title=$(basename "$file" | sed 's/\.[^.]*$//')
    local description="Uploaded: $title"
    
    # Upload to each selected platform
    for platform_idx in "${selected_platforms[@]}"; do
      local platform="${platforms[$platform_idx]}"
      case "$platform" in
        "YouTube")
          is_video "$file" && run_job "upload_youtube \"$file\" \"$title\" \"$description\""
          ;;
        "Telegram")
          run_job "upload_telegram \"$file\" \"$description\""
          ;;
        "Discord")
          run_job "upload_discord \"$file\" \"$description\""
          ;;
      esac
    done
  done
  
  wait
  log_info "All uploads completed!"
  read -p "Press Enter to continue..."
}

# Configure settings
configure_settings() {
  clear
  echo -e "${CYAN}=== Configuration ===${NC}"
  echo ""
  echo "1) Set source directory"
  echo "2) Set max concurrent jobs"
  echo "3) Configure API credentials"
  echo "4) Back"
  echo ""
  read -p "Select option: " choice
  
  case "$choice" in
    1)
      read -p "Source directory [$SOURCE_DIR]: " new_dir
      SOURCE_DIR="${new_dir:-$SOURCE_DIR}"
      ;;
    2)
      read -p "Max concurrent jobs [$MAX_CONCURRENT_JOBS]: " new_max
      MAX_CONCURRENT_JOBS="${new_max:-$MAX_CONCURRENT_JOBS}"
      ;;
    3)
      log_info "Edit $CONFIG_FILE to configure API credentials"
      log_info "Or set environment variables"
      ;;
  esac
  read -p "Press Enter to continue..."
}

# View logs
view_logs() {
  clear
  echo -e "${CYAN}=== Upload Logs ===${NC}"
  if [ ! -d "$LOG_DIR" ] || [ -z "$(ls -A "$LOG_DIR" 2>/dev/null)" ]; then
    log_warn "No logs found"
  else
    ls -lht "$LOG_DIR" | head -20
    echo ""
    read -p "Enter log filename to view (or press Enter to go back): " logfile
    if [ -n "$logfile" ] && [ -f "$LOG_DIR/$logfile" ]; then
      less "$LOG_DIR/$logfile"
    fi
  fi
  read -p "Press Enter to continue..."
}

# ==================== INITIALIZATION ====================
check_requirements

# Check if running interactively
if [ -t 0 ]; then
  main_menu
else
  # Non-interactive mode - upload all files
  log_info "Running in non-interactive mode"
  upload_all_files
fi
