#!/usr/bin/env bash
set -euo pipefail

SOURCE="$HOME/test-data"
DEST="$HOME/backups"
KEEP=7
STAMP=$(date +%Y-%m-%d_%H%M%S)
ARCHIVE="$DEST/backup_$STAMP.tar.gz"
LOG="$DEST/backup.log"

mkdir -p "$DEST"
log() { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

if [ ! -d "$SOURCE" ]; then
    log "ERROR: source folder $SOURCE not found"
    exit 1
fi

log "Starting backup of $SOURCE"
tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$(basename "$SOURCE")"
log "Created $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"

# Verify the archive can be read
if tar -tzf "$ARCHIVE" > /dev/null; then
    log "Archive verified"
else
    log "ERROR: archive failed verification"
    exit 1
fi

# Rotation: keep only the newest $KEEP archives
ls -1t "$DEST"/backup_*.tar.gz | tail -n +$((KEEP + 1)) | xargs -r rm --
log "Rotation complete (keeping last $KEEP)"
