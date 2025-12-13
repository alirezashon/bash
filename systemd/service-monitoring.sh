#!/bin/bash

# ================= CONFIG =================
LOG_FILE="/var/log/auth.log"
CHECK_INTERVAL=60        # seconds
FAILED_LIMIT=10          # threshold
STATE_FILE="/tmp/ssh_fail_count"
MAIL_TO="admin@localhost"
MAIL_FROM="alert@localhost"
# =========================================

touch "$STATE_FILE"

send_alert() {
cat <<EOF | sendmail "$MAIL_TO"
From: Server Monitor <$MAIL_FROM>
To: Admin <$MAIL_TO>
Subject: 🚨 SSH Attack Detected

Warning!

More than $FAILED_LIMIT failed SSH login attempts detected.
Time: $(date)
Server: $(hostname)

Check your server immediately.
EOF
}

while true; do
  FAILS=$(grep "Failed password" "$LOG_FILE" | wc -l)
  LAST_FAILS=$(cat "$STATE_FILE")

  if [ "$FAILS" -gt "$FAILED_LIMIT" ] && [ "$FAILS" -ne "$LAST_FAILS" ]; then
    send_alert
    echo "$FAILS" > "$STATE_FILE"
  fi

  sleep "$CHECK_INTERVAL"
done



--------------------------END--------------OF-----------------script----------run:
chmod +x /usr/local/bin/server-monitor.sh







systemd file :

[Unit]
Description=Simple Security Monitoring Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/server-monitor.sh
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target



---------------------------------------------

run :

systemctl daemon-reload
systemctl enable server-monitor
systemctl start server-monitor
