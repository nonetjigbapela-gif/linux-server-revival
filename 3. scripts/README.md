"set -euo pipefail" tells Linux to run the file with Bash and makes the script strict to prevent silent failures.
Then I declared the following variables:

SOURCE="$HOME/test-data" the folder to backup
DEST="$HOME/backups" where backups go
KEEP=7 how many to retain
STAMP=$(date +%Y-%m-%d_%H%M%S)
ARCHIVE="$DEST/backup_$STAMP.tar.gz" builds the full file name from pieces above
LOG="$DEST/backup.log"

mkdir -p "$DEST"
log() { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

creates the backup folder & defines a reusable function. The quotes are used to protect against spaces in file names.

if [ ! -d "$SOURCE" ]; then
    log "ERROR: source folder $SOURCE not found"
    exit 1
fi

This checks if this is an existing directory and flips it so it reads "if the source is Not a directory". If so then the scrips logs an error & exit 1 stops it. Exit code 0 means success and anything else means failure, which matters later when cron or other tools check the result. fi closes the if statement. This block stops the script from creating an empty or broken backup of a folder that doesn't exist.

log "Starting backup of $SOURCE"
tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$(basename "$SOURCE")"
log "Created $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"

An archive is created, then compressed with gzip & says "the next argument is the file name". Tar is then told to move into that folder first. dirname "$SOURCE" gives /home/labserver and basename "$SOURCE" gives test-data. Together, tar enters /home/labserver and archives just test-data, so the archive contains test-data/notes.txt rather than the full absolute path. That’s why your restore produced a clean test-data folder. On the log line, du -h "$ARCHIVE" reports the file size in human-readable form, and cut -f1 keeps only the first column (the size, without the file name).

if tar -tzf "$ARCHIVE" > /dev/null; then
    log "Archive verified"
else
    log "ERROR: archive failed verification"
    exit 1
fi

tar -tzf lists the archive’s contents (t) instead of extracting. If the archive is corrupt, this fails. > /dev/null throws away the file listing, since you only care whether it worked.if command; then ... else ... fi runs the first branch if the command succeeded and the second if it failed. Normally set -e would kill the script when tar fails. Commands used as an if condition are exempt, which is why the else branch can run and log a proper error.

ls -1t "$DEST"/backup_*.tar.gz | tail -n +$((KEEP + 1)) | xargs -r rm --

This is a pipeline, so read it left to right. Archives are listed one per line, then prints from line 8 onwards. $((KEEP + 1)) is arithmetic (7 + 1 = 8), so lines 1 to 7 (the newest seven) are skipped and everything older is passed on. xargs -r rm -- takes those file names and runs rm on them. -r means “don’t run if there’s nothing to delete”, and -- marks the end of options, so a file name starting with - can’t be misread as a flag. This is why your 10-run test should leave exactly 7 archives.
