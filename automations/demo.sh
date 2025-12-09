#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# Demo Script - نمایش قابلیت‌های سیستم
# این اسکریپت یک دمو کامل از سیستم مدیریت محتوا ارائه می‌دهد
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENT_MANAGER="$SCRIPT_DIR/content_manager.sh"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          🎬 CONTENT MANAGEMENT SYSTEM DEMO 🎬            ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Source content manager
if [ -f "$CONTENT_MANAGER" ]; then
  source "$CONTENT_MANAGER"
else
  echo "Error: content_manager.sh not found" >&2
  exit 1
fi

# Create demo data
create_demo_data() {
  echo -e "${BLUE}📝 Creating demo data...${NC}"
  
  # Create temporary demo files
  local demo_dir="./demo_content"
  mkdir -p "$demo_dir"
  
  # Create some dummy files for demo
  echo "Demo video content" > "$demo_dir/demo_video.mp4"
  echo "Demo image content" > "$demo_dir/demo_image.jpg"
  echo "Demo image 2" > "$demo_dir/demo_image2.png"
  
  # Add demo entries to database
  init_database
  
  # Add some sample uploads
  add_content "$demo_dir/demo_video.mp4" "YouTube" "success" '{"views": 1250, "likes": 45}'
  add_content "$demo_dir/demo_image.jpg" "Instagram" "success" '{"likes": 120, "comments": 8}'
  add_content "$demo_dir/demo_image2.png" "Telegram" "success" '{"views": 500}'
  add_content "$demo_dir/demo_video.mp4" "Discord" "success" '{}'
  add_content "$demo_dir/demo_image.jpg" "Instagram" "failed" '{"error": "API limit exceeded"}'
  
  echo -e "${GREEN}✓ Demo data created${NC}"
  echo ""
}

# Show demo dashboard
show_demo_dashboard() {
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}📊 DEMO: Dashboard View${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  show_dashboard
  echo ""
}

# Demo search
demo_search() {
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}🔍 DEMO: Search Functionality${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "Searching for 'demo' in file names:"
  search_content "demo" "name" | while IFS='|' read -r id name platform status; do
    printf "  %-20s %-30s %-15s %s\n" "$id" "$name" "$platform" "$status"
  done
  echo ""
  
  echo "Searching for 'YouTube' platform:"
  search_content "YouTube" "platform" | while IFS='|' read -r id name platform status; do
    printf "  %-20s %-30s %-15s %s\n" "$id" "$name" "$platform" "$status"
  done
  echo ""
}

# Demo export
demo_export() {
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}📤 DEMO: Export Reports${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "Exporting JSON report..."
  local json_file=$(export_json)
  echo -e "${GREEN}✓ JSON exported: $json_file${NC}"
  echo ""
  
  echo "Exporting CSV report..."
  local csv_file=$(export_csv)
  echo -e "${GREEN}✓ CSV exported: $csv_file${NC}"
  echo ""
  
  echo "Exporting HTML report..."
  local html_file=$(export_html)
  echo -e "${GREEN}✓ HTML exported: $html_file${NC}"
  echo -e "${BLUE}  Open in browser: file://$(realpath "$html_file")${NC}"
  echo ""
}

# Demo backup
demo_backup() {
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}💾 DEMO: Backup System${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  echo "Creating backup..."
  local backup_file=$(create_backup)
  echo -e "${GREEN}✓ Backup created: $backup_file${NC}"
  echo ""
  
  echo "Listing backups:"
  list_backups
  echo ""
}

# Demo optimization
demo_optimization() {
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}💡 DEMO: Optimization Suggestions${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  get_optimization_suggestions
}

# Main demo flow
main() {
  echo -e "${GREEN}Starting demo...${NC}"
  echo ""
  
  # Step 1: Create demo data
  create_demo_data
  
  # Step 2: Show dashboard
  show_demo_dashboard
  
  # Step 3: Demo search
  demo_search
  
  # Step 4: Demo export
  demo_export
  
  # Step 5: Demo backup
  demo_backup
  
  # Step 6: Demo optimization
  demo_optimization
  
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}✅ Demo completed!${NC}"
  echo ""
  echo -e "${BLUE}Next steps:${NC}"
  echo "  1. Run './content_manager.sh' for full interactive experience"
  echo "  2. Run './upload.sh' to upload real content"
  echo "  3. Check PROJECT_README.md for detailed documentation"
  echo ""
  
  # Cleanup option
  read -p "Clean up demo data? (y/N): " cleanup
  if [[ "$cleanup" =~ ^[Yy]$ ]]; then
    rm -rf "./demo_content"
    rm -rf "./content_db"
    rm -rf "./content_backups"
    rm -rf "./content_reports"
    echo -e "${GREEN}✓ Demo data cleaned${NC}"
  else
    echo -e "${YELLOW}Demo data kept in: ./demo_content, ./content_db${NC}"
  fi
}

# Run demo
main

