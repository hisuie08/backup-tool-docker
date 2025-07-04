#!/bin/bash
set -eo pipefail

# 環境変数読み込み
if [ -f /root/env.sh ]; then
  . /root/env.sh
fi
: "${SOURCE_DIR:?}"
: "${BACKUP_DIR:?}"
: "${LOCK_FILE:?}"
: "${LOG_FILE:?}"
: "${TEMP_DIR:?}"
: "${RETAINED:?}"
: "${RSYNC_OPTS:?}"

# ログ出力
log() {
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] $1"
}


# 必要なディレクトリ作成
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")" "$TEMP_DIR"

# メイン処理
run_backup() {
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  DEST="$BACKUP_DIR/backup-$TIMESTAMP"

  LATEST=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name 'backup-*' | sort -r | head -n 1 || true)

  log "[+] Starting backup to $DEST"
  mkdir -p "$DEST"

  if [ -n "$LATEST" ] && [ -d "$LATEST" ]; then
    rsync $RSYNC_OPTS --link-dest="$LATEST" --temp-dir="$TEMP_DIR" "$SOURCE_DIR/" "$DEST"
  else
    rsync $RSYNC_OPTS --temp-dir="$TEMP_DIR" "$SOURCE_DIR/" "$DEST"
  fi

  log "[✓] Backup completed: $DEST"

  # 保持数チェックと削除
  if [ "$RETAINED" -gt 0 ]; then
    BACKUPS=( $(find "$BACKUP_DIR" -maxdepth 1 -type d -name 'backup-*' | sort -r) )
    COUNT=${#BACKUPS[@]}
    if [ "$COUNT" -gt "$RETAINED" ]; then
      for b in "${BACKUPS[@]:$RETAINED}"; do
        log "[-] Removing old backup: $b"
        rm -rf "$b"
      done
    fi
  fi
}

# 排他ロック制御
mkdir -p "$(dirname "$LOCK_FILE")"
exec 9>"$LOCK_FILE"
if flock -n 9; then
  echo "PID $$ started at $(date '+%Y-%m-%d %H:%M:%S')" > "$LOCK_FILE"
  run_backup
  rm -f "$LOCK_FILE"
else
  log "[!] Lock file exists. Another backup is already running."
fi