#!/bin/bash

# Simple Linux Server Monitoring Script

LOGFILE="server_health.log"
DATE=$(date)

# Telegram configuration
BOT_TOKEN="8744580645:AAE0yMEDOqKnM0WAPATuiaGBr4v9ehxs1Ko"
CHAT_ID="6851023308"

send_telegram () {
MESSAGE=$1
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
-d chat_id=$CHAT_ID \
-d text="$MESSAGE" > /dev/null
}


echo "---------------------------" >> $LOGFILE
echo "Server Check Time: $DATE" >> $LOGFILE

# Check CPU usage
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}')
echo "CPU Usage: $CPU%" >> $LOGFILE
sudo yum install bc -y

if (( $(echo "$CPU > 60" | bc -l) ))
then
echo "Warning: CPU usage is high!" >> $LOGFILE
send_telegram "🚨 CPU ALERT: $CPU% usage on $(hostname)"
fi


# Check Memory usage
MEM=$(free | awk '/Mem/ {printf("%.2f"), $3/$2 * 100}')
echo "Memory Usage: $MEM%" >> $LOGFILE

if (( $(echo "$MEM > 80" | bc -l) ))
then
echo "Warning: Memory usage is high!" >> $LOGFILE
send_telegram "🚨 MEMORY ALERT: $MEM% usage on $(hostname)"
fi


# Check Disk usage
DISK=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
echo "Disk Usage: $DISK%" >> $LOGFILE

if [ $DISK -gt 80 ]
then
echo "Warning: Disk usage is high!" >> $LOGFILE
send_telegram "⚠️ DISK ALERT: $DISK% used on $(hostname)"
fi


# Check SSH service
sudo yum install openssh-server  -y
sudo systemctl start sshd
sudo systemctl enable sshd
STATUS=$(systemctl is-active sshd)

if [ "$STATUS" != "active" ]
then
echo "SSH is not running. Restarting service..." >> $LOGFILE
sudo systemctl restart sshd
send_telegram "⚠️ SSH service was down and restarted on $(hostname)"
else
echo "SSH service is running normally." >> $LOGFILE
fi

echo "Check completed" >> $LOGFILE
