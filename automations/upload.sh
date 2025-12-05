#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------
# multi_upload.sh
# Upload videos/images from a folder to multiple platforms concurrently.
# Edit the TOKEN / CONFIG section below with your API keys / tokens.
# Important: Many APIs require OAuth flows & extra steps (see notes).
# ---------------------------------------------

# ------------- CONFIG (HARD-CODED) -------------
# Put your tokens/keys here (replace example values).
# SECURITY NOTE: Hardcoding tokens is convenient for quick scripts but insecure.
# Consider storing in env vars or a vault for production.

# YouTube (Google APIs) - requires OAuth 2.0 with access_token (and possibly refresh_token)
YOUTUBE_ACCESS_TOKEN="ya29.ABCDE_EXAMPLE"   # OAuth 2.0 access token with youtube.upload scope
YOUTUBE_CHANNEL_ID="UCxxxxxxxxxxxx"

# Telegram - Bot token and target chat id
TELEGRAM_BOT_TOKEN="123456:ABCDEF-your-telegram-bot-token"
TELEGRAM_CHAT_ID="@your_channel_or_chat_id_or_numeric"

# Instagram Graph API (Business/Creator) - requires access token & instagram_business_account
IG_ACCESS_TOKEN="IGQVJ...EXAMPLE"
IG_INSTAGRAM_ACCOUNT_ID="178414xxxxx"  # the instagramBusinessAccount id

# Discord - webhook (simplest) or bot token + channel
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/ID/TOKEN"

# X (Twitter) - Bearer token for OAuth2 or OAuth1.0a credentials for media + tweet
X_BEARER_TOKEN="AAAAAAAAA...EXAMPLE"
# For uploading media to X you likely need OAuth 1.0a with consumer & access tokens (not shown)

# Reddit - OAuth2 access token for script-type app
REDDIT_ACCESS_TOKEN="bEARER_EXAMPLE"
REDDIT_SUBREDDIT="yoursubreddit"

# General settings
SOURCE_DIR="./to_upload"   # folder to scan for media
MAX_CONCURRENT_JOBS=4      # adjust to control concurrency
LOG_DIR="./upload_logs"
mkdir -p "$LOG_DIR"

# Allowed file extensions (video and images). Extend if needed.
EXT_PATTERN="\( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.mkv' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \)"

# ---------------------------------------------
# helper: semaphore to limit concurrency
# usage: run_job <cmd...>
JOB_COUNT=0
jobs_pids=()

run_job() {
  local cmd="$*"
  # start in background
  bash -c "$cmd" &
  pid=$!
  jobs_pids+=($pid)
  JOB_COUNT=$((JOB_COUNT+1))

  # if reached limit, wait for one to finish
  while [ "${JOB_COUNT}" -ge "$MAX_CONCURRENT_JOBS" ]; do
    # wait -n waits for any background job to finish (bash 4.3+)
    if wait -n 2>/dev/null; then
      JOB_COUNT=$((JOB_COUNT-1))
    else
      # fallback: wait for first pid
      wait "${jobs_pids[0]}" && JOB_COUNT=$((JOB_COUNT-1))
      jobs_pids=("${jobs_pids[@]:1}")
    fi
  done
}

# ---------------------------------------------
# Upload functions for each platform
# Each function should return non-zero on failure and print logs.
# NOTE: For many platforms this is a simplified single-step curl — real-world usage may require multi-step.
# ---------------------------------------------

upload_youtube() {
  local file="$1"
  local title="$2"
  local description="$3"
  local logfile="$LOG_DIR/youtube_$(basename "$file").log"

  echo "Uploading to YouTube: $file" | tee "$logfile"
  # NOTE: YouTube requires multipart upload to https://www.googleapis.com/upload/youtube/v3/videos?uploadType=multipart
  # This example is the minimal multipart approach; in production you should use resumable upload for large files.
  resp=$(curl -s -X POST \
    -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
    -H "Accept: application/json" \
    -F "snippet={\"title\":\"$title\",\"description\":\"$description\"};type=application/json; charset=UTF-8" \
    -F "status={\"privacyStatus\":\"public\"};type=application/json; charset=UTF-8" \
    -F "media=@\"$file\";type=$(file --brief --mime-type "$file")" \
    "https://www.googleapis.com/upload/youtube/v3/videos?part=snippet,status" )

  echo "$resp" >> "$logfile"
  if echo "$resp" | jq -e '.id' >/dev/null 2>&1; then
    echo "YouTube upload success: $(echo "$resp" | jq -r '.id')" | tee -a "$logfile"
    return 0
  else
    echo "YouTube upload failed: $(cat "$logfile")" >&2
    return 1
  fi
}

upload_telegram() {
  local file="$1"
  local caption="$2"
  local logfile="$LOG_DIR/telegram_$(basename "$file").log"

  echo "Uploading to Telegram: $file" | tee "$logfile"
  # Telegram: use sendVideo or sendDocument depending on file
  mime=$(file --brief --mime-type "$file")
  if [[ "$mime" == video/* ]]; then
    method="sendVideo"
    field_name="video"
  else
    method="sendDocument"
    field_name="document"
  fi

  resp=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/${method}" \
    -F "chat_id=${TELEGRAM_CHAT_ID}" \
    -F "${field_name}=@${file}" \
    -F "caption=${caption}" )

  echo "$resp" >> "$logfile"
  if echo "$resp" | jq -e '.ok' >/dev/null 2>&1; then
    echo "Telegram upload success" | tee -a "$logfile"
    return 0
  else
    echo "Telegram upload failed: $(cat "$logfile")" >&2
    return 1
  fi
}

upload_discord() {
  local file="$1"
  local content="$2"
  local logfile="$LOG_DIR/discord_$(basename "$file").log"

  echo "Uploading to Discord via webhook: $file" | tee "$logfile"
  # Discord webhook: multipart/form-data with 'file'
  resp=$(curl -s -X POST "$DISCORD_WEBHOOK_URL" \
    -F "content=$content" \
    -F "file=@${file}" )

  echo "$resp" >> "$logfile"
  # Discord returns JSON on success or error
  if echo "$resp" | jq -e '.id' >/dev/null 2>&1 || echo "$resp" | jq -e '.attachments' >/dev/null 2>&1; then
    echo "Discord upload success" | tee -a "$logfile"
    return 0
  else
    echo "Discord upload failed: $(cat "$logfile")" >&2
    return 1
  fi
}

upload_x() {
  local file="$1"
  local status="$2"
  local logfile="$LOG_DIR/x_$(basename "$file").log"

  echo "Uploading to X (Twitter): $file" | tee "$logfile"
  # NOTE: Twitter/X media upload is multi-step (INIT, APPEND, FINALIZE) with OAuth1.0a.
  # Here we'll show a placeholder using OAuth2 Bearer (which cannot upload media). So this will likely fail unless you implement OAuth1.0a.
  echo "{\"note\":\"This script contains a placeholder for X/Twitter. Implement OAuth1.0a media upload (INIT/APPEND/FINALIZE) for real uploads.\"}" | tee -a "$logfile"
  return 1
}

upload_reddit() {
  local file="$1"
  local title="$2"
  local subreddit="$REDDIT_SUBREDDIT"
  local logfile="$LOG_DIR/reddit_$(basename "$file").log"

  echo "Uploading to Reddit: $file" | tee "$logfile"
  # Reddit API for media posts requires creating an upload URL via /api/v1/media/asset.json and then submitting a post.
  echo "{\"note\":\"Reddit media upload requires multi-step upload and proper OAuth scopes. Placeholder only.\"}" | tee -a "$logfile"
  return 1
}

upload_instagram() {
  local file="$1"
  local caption="$2"
  local logfile="$LOG_DIR/instagram_$(basename "$file").log"

  echo "Uploading to Instagram Graph API: $file" | tee "$logfile"
  # Instagram: Create media container, then publish. Requires IG business account and permissions.
  # Step 1: create container
  create_resp=$(curl -s -X POST "https://graph.facebook.com/v17.0/${IG_INSTAGRAM_ACCOUNT_ID}/media" \
    -F "access_token=${IG_ACCESS_TOKEN}" \
    -F "video_url=@${file}" \
    -F "caption=${caption}" 2>/dev/null || true)

  echo "$create_resp" >> "$logfile"
  echo "{\"note\":\"This is a simplified placeholder. For local file you must host it where IG can fetch, or use resumable upload via the Graph API.\"}" | tee -a "$logfile"
  return 1
}

# ---------------------------------------------
# Main: iterate files in SOURCE_DIR and call uploaders
# ---------------------------------------------
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Source directory $SOURCE_DIR does not exist. Create it and put media files there." >&2
  exit 1
fi

# find files
mapfile -t files < <(find "$SOURCE_DIR" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print)

if [ "${#files[@]}" -eq 0 ]; then
  echo "No media files found in $SOURCE_DIR" >&2
  exit 1
fi

echo "Found ${#files[@]} files. Starting uploads with concurrency=${MAX_CONCURRENT_JOBS}..."

for f in "${files[@]}"; do
  fname=$(basename "$f")
  title="${fname%.*}"
  description="Uploaded by multi_upload.sh - $title"

  # For each platform we spawn background job using run_job
  # You may pick which platforms to enable by commenting/uncommenting lines below.

  # YouTube
  run_job "upload_youtube \"$f\" \"$title\" \"$description\" || echo 'YouTube failed for $f'"

  # Telegram
  run_job "upload_telegram \"$f\" \"$description\" || echo 'Telegram failed for $f'"

  # Discord
  run_job "upload_discord \"$f\" \"${description}\" || echo 'Discord failed for $f'"

  # Instagram
  run_job "upload_instagram \"$f\" \"$description\" || echo 'Instagram failed for $f'"

  # X / Twitter (placeholder)
  run_job "upload_x \"$f\" \"$description\" || echo 'X upload placeholder failed for $f'"

  # Reddit (placeholder)
  run_job "upload_reddit \"$f\" \"$title\" || echo 'Reddit upload placeholder failed for $f'"

done

# wait for remaining jobs
wait
echo "All jobs finished."
