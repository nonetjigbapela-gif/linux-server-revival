#!/usr/bin/env bash
set -euo pipefail

DISK_LIMIT=${DISK_LIMIT:-80}
MEM_LIMIT=${MEM_LIMIT:-85}
LOAD_LIMIT=${LOAD_LIMIT:-2.0}
LOG="$HOME/monitor.log"

log() { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

DISK=$(df / --output=pcent | tail -1 | tr -dc '0-9')
MEM=$(free | awk '/Mem:/ {printf "%d", ($2-$7)/$2*100}')
LOAD=$(cut -d' ' -f1 /proc/loadavg)

log "STATUS disk=${DISK}% mem=${MEM}% load=${LOAD} ($(uptime -p))"

if [ "$DISK" -ge "$DISK_LIMIT" ]; then
    log "ALERT: disk usage ${DISK}% is at or above ${DISK_LIMIT}%"
fi
if [ "$MEM" -ge "$MEM_LIMIT" ]; then
    log "ALERT: memory usage ${MEM}% is at or above ${MEM_LIMIT}%"
fi
if awk -v a="$LOAD" -v b="$LOAD_LIMIT" 'BEGIN{exit !(a>b)}'; then
    log "ALERT: load average ${LOAD} is above ${LOAD_LIMIT}"
fi
