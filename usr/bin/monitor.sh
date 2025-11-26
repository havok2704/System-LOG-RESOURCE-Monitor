#!/bin/bash
# -----------------------------------------------------------
# System Resource & Log Monitor with Telegram Alerts
# -----------------------------------------------------------

# Ensure PATH works inside cron
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ---------------- TELEGRAM SETTINGS ------------------------
BOT_TOKEN="8246140062:AAE_VkX3vI6p_9KhtSsYWoHPeE-DUPP6NLQ"
CHAT_ID="1922143160"


# ---------------- THRESHOLDS -------------------------------
CPU_THRESHOLD=85
MEM_THRESHOLD=85
DISK_THRESHOLD=85

# ---------------- LOG SETTINGS -----------------------------
LOG_KEYWORDS="error|failed|critical|panic"
DATA_LOG_FILE="/var/log/monitor_data.csv"

# ---------------- TEST MODE CHECK --------------------------
SEND_TEST_ALERTS=false
if [[ "$1" == "--test" ]]; then
    echo "[TEST MODE] Sending forced alerts."
    CPU_USAGE=95
    MEM_USAGE=95
    DISK_USAGE=95
    LOG_FOUND="yes"
    SEND_TEST_ALERTS=true
else
    # ---------------- GET CPU USAGE ------------------------
    # top output e.g.: %Cpu(s):  5.0 us,  3.0 sy,  0.0 ni, 90.0 id
    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}')
    CPU_USAGE=$(echo "100 - $CPU_IDLE" | bc)
    CPU_USAGE=${CPU_USAGE%.*}

    # ---------------- GET MEMORY USAGE ---------------------
    MEM_USAGE=$(free | awk '/Mem/ {printf "%.0f", $3/$2*100}')

    # ---------------- GET DISK USAGE -----------------------
    DISK_USAGE=$(df / | awk 'END{gsub("%","",$5); print $5}')

    # ---------------- CHECK LOGS ---------------------------
    journalctl -p err -n 50 2>/dev/null | grep -Eiq "$LOG_KEYWORDS"
    if [[ $? -eq 0 ]]; then
        LOG_FOUND="yes"
    else
        LOG_FOUND="no"
    fi
fi

# ---------------- FUNCTION: SEND TELEGRAM ALERT -------------
send_alert() {
    local MESSAGE="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${MESSAGE}" >/dev/null 2>&1
}

# ---------------- SEND ALERTS -------------------------------
if (( CPU_USAGE > CPU_THRESHOLD )) || [[ "$SEND_TEST_ALERTS" == true ]]; then
    send_alert "⚠️ HIGH CPU USAGE: ${CPU_USAGE}%"
fi

if (( MEM_USAGE > MEM_THRESHOLD )) || [[ "$SEND_TEST_ALERTS" == true ]]; then
    send_alert "⚠️ HIGH MEMORY USAGE: ${MEM_USAGE}%"
fi

if (( DISK_USAGE > DISK_THRESHOLD )) || [[ "$SEND_TEST_ALERTS" == true ]]; then
    send_alert "⚠️ LOW DISK SPACE: ${DISK_USAGE}% on /"
fi

if [[ "$LOG_FOUND" == "yes" ]] || [[ "$SEND_TEST_ALERTS" == true ]]; then
    send_alert "⚠️ SYSTEM LOG ALERT: Error-level messages detected."
fi

# ---------------- CSV LOGGING -------------------------------
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Create CSV file with header if empty or missing
if [[ ! -s "$DATA_LOG_FILE" ]]; then
    echo "timestamp,cpu,mem,disk,log_issue" | sudo tee "$DATA_LOG_FILE" >/dev/null
fi

echo "$TIMESTAMP,$CPU_USAGE,$MEM_USAGE,$DISK_USAGE,$LOG_FOUND" \
    | sudo tee -a "$DATA_LOG_FILE" >/dev/null
