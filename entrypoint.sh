#!/bin/bash
set -e

# cronに読ませるための環境変数スクリプト
printenv | awk '{print "export " $1}' > /root/env.sh

# cron登録
echo "$CRON_INTERVAL bash /app/backup.sh >> $LOG_FILE 2>&1" > /etc/cron.d/rsync-backup
chmod 0644 /etc/cron.d/rsync-backup
crontab /etc/cron.d/rsync-backup
echo "[$(date +%Y-%m-%dT%H:%M:%S)] [i] Cron scheduled: $CRON_INTERVAL" >> "$LOG_FILE"

# スケジュールに関係なくプロセス起動時もバックアップ
# 要らなければコメントアウトか削除
bash /app/backup.sh

cron -f
