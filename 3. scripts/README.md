# -scripts: backup and monitoring scripts

Two Bash scripts that keep the server backed up and watched. They are scheduled to run automatically (see [`../04-automation/`](../04-automation/)).

| Script | Purpose |
|---|---|
| [`backup.sh`](backup.sh) | Compresses a folder into a timestamped archive, verifies it, and deletes the oldest archives |
| [`monitor.sh`](monitor.sh) | Logs disk, memory and CPU load, and records an `ALERT` line when a threshold is crossed |

## Requirements

- Linux with Bash 4 or newer (tested on Lubuntu [version] on a Dell Inspiron 3551, 2 GB RAM)
- Standard tools: `tar`, `gzip`, `df`, `free`, `awk`, `cut`, `tr`, `du`, `xargs`
- No root access needed. Both scripts work inside the user's home folder.

## Quick start

```bash
chmod +x backup.sh monitor.sh
./backup.sh
./monitor.sh
```

Both scripts use strict mode (`set -euo pipefail`), so they stop on errors instead of failing silently, and both write timestamped lines to a log file.

| File | Written by | Location |
|---|---|---|
| Backup archives | `backup.sh` | `~/backups/backup_YYYY-MM-DD_HHMMSS.tar.gz` |
| Backup log | `backup.sh` | `~/backups/backup.log` |
| Monitor log | `monitor.sh` | `~/monitor.log` |

---

## backup.sh: automated backup with rotation

Compresses a folder into a timestamped archive, verifies that the archive can be read, logs every step, and keeps only the newest few archives.

### What it does

1. Checks that the source folder exists, and stops with an error if it doesn't.
2. Creates a compressed archive (`.tar.gz`) named with the date and time.
3. Verifies the archive by listing its contents.
4. Deletes all but the newest 7 archives (rotation).
5. Logs each step with a timestamp.

### Configuration

Set at the top of the script:

| Variable | Default | Purpose |
|---|---|---|
| `SOURCE` | `$HOME/test-data` | Folder to back up |
| `DEST` | `$HOME/backups` | Where archives and the log are stored |
| `KEEP` | `7` | Number of archives to retain |

### Example output

```
2026-10-29 22:15:00 Starting backup of /home/[user]/test-data
2026-10-29 22:15:00 Created /home/[user]/backups/backup_2026-10-29_221500.tar.gz ([size])
2026-10-29 22:15:00 Archive verified
2026-10-29 22:15:00 Rotation complete (keeping last 7)
```

### Restoring from a backup

```bash
mkdir -p ~/restore-test
tar -xzf ~/backups/backup_<timestamp>.tar.gz -C ~/restore-test
```

The files come back inside a `test-data/` folder, because the archive was created with relative paths.

### How it works

- **Strict mode** stops the script on any error or undefined variable.
- **Timestamped names** come from `date +%Y-%m-%d_%H%M%S`, so each archive gets a unique name.
- **A `log` function** prints each message with a timestamp and appends it to the log file (`tee -a`).
- **`tar -czf` with `-C`** creates a gzip-compressed archive while changing into the parent folder first, so the archive holds `test-data/...` rather than an absolute path.
- **Verification** uses `tar -tzf`, which lists the contents without extracting. A corrupt archive makes it fail, and the script logs an error and exits with a non-zero code.
- **Rotation** is a pipeline. `ls -1t` lists archives newest first, `tail -n +8` selects everything after the newest 7, and `xargs -r rm --` deletes them (`-r` does nothing when the list is empty, and `--` protects against file names starting with `-`).

### Tests

| Test | How | Expected result | Result |
|---|---|---|---|
| Normal backup | Run `./backup.sh` | Archive created, verified and logged | [pass/fail] |
| Restore | Delete the source folder, extract the archive elsewhere | Files return intact and match the originals | [pass/fail] |
| Missing source | Run the script with the source folder removed | `ERROR: source folder ... not found`, exit code 1 (check with `echo $?`) | [pass/fail] |
| Rotation | Run the script 10 times with a 1-second pause between runs | Exactly 7 archives remain | [pass/fail] |

---

## monitor.sh: system health monitor

Checks disk, memory and CPU load, writes a timestamped status line to a log, and records an `ALERT` line whenever a value crosses a threshold.

### What it checks

| Metric | How it's measured | Default threshold |
|---|---|---|
| Disk usage | Percentage used on the root filesystem (`df /`) | 80% |
| Memory usage | Percentage of RAM in use, calculated from the *available* figure in `free` (more accurate than "free", because it counts reclaimable cache) | 85% |
| CPU load | 1-minute load average from `/proc/loadavg` | 2.0 (the laptop's Celeron has 2 cores, so a sustained load above 2.0 means the CPU is saturated) |

### Example output

```
2026-10-29 22:30:01 STATUS disk=[5]% mem=[48]% load=[0.21] (up [2 hours, 10 minutes])
2026-10-29 22:30:01 ALERT: disk usage 91% is at or above 80%
```

The `ALERT` line only appears when a threshold is crossed.

### Changing the thresholds

Thresholds can be overridden per run without editing the script:

```bash
DISK_LIMIT=90 MEM_LIMIT=70 LOAD_LIMIT=1.5 ./monitor.sh
```

### How it works

1. **Strict mode** stops the script on errors and undefined variables.
2. **Configurable limits** use the `${VAR:-default}` pattern, so each value falls back to its default unless set in the environment.
3. **A `log` function** prints each message with a timestamp and appends it to the log file.
4. **Data collection:**
   - Disk: `df` prints the usage percentage, and `tr -dc '0-9'` strips everything except the digits.
   - Memory: `awk` calculates `(total - available) / total * 100` from the `free` output.
   - Load: `cut` takes the first field of `/proc/loadavg`.
5. **Checks:** disk and memory are compared as integers with `-ge`. Load is a decimal number, which Bash can't compare natively, so `awk` does that comparison.

### Tests

| Test | Command | Expected result | Result |
|---|---|---|---|
| Normal run | `./monitor.sh` | One `STATUS` line, no alerts | [pass/fail] |
| Forced alerts | `DISK_LIMIT=1 MEM_LIMIT=1 ./monitor.sh` | `STATUS` line plus disk and memory `ALERT` lines | [pass/fail] |
| Load alert | `LOAD_LIMIT=0.0 ./monitor.sh` | `STATUS` line plus a load `ALERT` line | [pass/fail] |
| Real disk alert | Create a large temporary file, set `DISK_LIMIT` just below the new usage, run the script, then delete the file | Disk `ALERT` line | [pass/fail] |

---

## Limitations

- **Backups are stored on the same disk as the data.** If the drive fails, both are lost. Copying archives to another machine (for example with `scp` or `rsync` over SSH) is planned.
- `backup.sh` backs up one fixed folder and doesn't encrypt the archives. Rotation is by count, not by age or free disk space.
- `monitor.sh` only reports the root filesystem, and alerts are written to the log only (no email or push notification).
- Thresholds are fixed values and aren't tuned to the machine's normal behaviour.
- Log files grow without limit until log rotation is added.
- Scheduling depends on the laptop being awake. See [`../04-automation/`](../04-automation/) for details.

## Possible improvements

- Copy backups off the machine and test restoring from the copy
- Add `logrotate` for `monitor.log` and `backup.log`
- Send alerts by email or messaging instead of only logging them
- Take the backup source from a config file or command-line argument
