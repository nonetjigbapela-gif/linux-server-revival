## backup.sh: automated backup with rotation

A Bash script that compresses a folder into a timestamped archive, verifies the archive can be read, logs every step, and deletes the oldest archives so only the newest few are kept.

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

### Usage

```bash
chmod +x backup.sh
./backup.sh
```

Example output:

```
2026-10-29 22:15:00 Starting backup of /home/[user]/test-data
2026-10-29 22:15:00 Created /home/[user]/backups/backup_2026-10-29_221500.tar.gz ([4.0K])
2026-10-29 22:15:00 Archive verified
2026-10-29 22:15:00 Rotation complete (keeping last 7)
```

Archives are named `backup_YYYY-MM-DD_HHMMSS.tar.gz`, and the log is `~/backups/backup.log`.

### Restoring from a backup

```bash
mkdir -p ~/restore-test
tar -xzf ~/backups/backup_<timestamp>.tar.gz -C ~/restore-test
```

The files come back inside a `test-data/` folder, because the archive was created with relative paths.

### How it works

- **Strict mode** (`set -euo pipefail`) stops the script on any error or undefined variable, instead of continuing silently.
- **Timestamped names** come from `date +%Y-%m-%d_%H%M%S`, so each archive gets a unique name.
- **A `log` function** prints each message with a timestamp and appends it to the log file (`tee -a`).
- **`tar -czf` with `-C`** creates a gzip-compressed archive while changing into the parent folder first, so the archive holds `test-data/...` instead of a full absolute path.
- **Verification** uses `tar -tzf`, which lists the archive's contents without extracting. A corrupt archive makes it fail, and the script logs an error and exits with a non-zero code.
- **Rotation** is a pipeline: `ls -1t` lists archives newest first, `tail -n +8` keeps only those after the newest 7, and `xargs -r rm --` deletes them (`-r` does nothing if the list is empty, and `--` protects against file names starting with `-`).

### Testing

| Test | How | Expected result | Result |
|---|---|---|---|
| Normal backup | Run `./backup.sh` | Archive created, verified, logged | [pass/fail] |
| Restore | Delete the source folder, extract the archive to a new location | Files return intact, contents match | [pass/fail] |
| Missing source | Run the script with the source folder removed | `ERROR: source folder ... not found`, exit code 1 | [pass/fail] |
| Rotation | Run the script 10 times (with a 1-second pause between runs) | Exactly 7 archives remain | [pass/fail] |

Check the exit code of the missing-source test with `echo $?` straight after the run. It should print `1`.

### Limitations

- **Backups are stored on the same disk as the data.** If the drive fails, both are lost. Copying archives to another machine is planned (for example, with `scp` or `rsync` over SSH).
- It backs up one fixed folder. Multiple sources would need a loop or a config file.
- The archive isn't encrypted or password protected.
- Rotation is by count, not by age or by free disk space.
- It has to be scheduled (see `04-automation/`) to run unattended.



## monitor.sh: system health monitor

A Bash script that checks disk, memory, and CPU load on the server, writes a timestamped status line to a log, and records an `ALERT` line whenever a value crosses a threshold.

### What it checks

| Metric | How it's measured | Default threshold |
|---|---|---|
| Disk usage | Percentage used on the root filesystem (`df /`) | 80% |
| Memory usage | Percentage of RAM in use, calculated from the *available* figure in `free` (more accurate than "free", because it counts reclaimable cache) | 85% |
| CPU load | 1-minute load average from `/proc/loadavg` | 2.0 (the laptop's Celeron has 2 cores, so a sustained load above 2.0 means the CPU is saturated) |

### Usage

```bash
chmod +x monitor.sh
./monitor.sh
```

Each run appends to `~/monitor.log`. Example output:

```
2026-10-29 22:30:01 STATUS disk=[5]% mem=[48]% load=[0.21] (up [2 hours, 10 minutes])
```

When a threshold is crossed, an extra line is written:

```
2026-10-29 22:30:01 ALERT: disk usage 91% is at or above 80%
```

### Changing the thresholds

Thresholds can be overridden per run without editing the script:

```bash
DISK_LIMIT=90 MEM_LIMIT=70 LOAD_LIMIT=1.5 ./monitor.sh
```

### How it works

1. **Strict mode** (`set -euo pipefail`) makes the script stop on errors and on undefined variables, instead of failing silently.
2. **Configurable limits** use the `${VAR:-default}` pattern, so each value falls back to its default unless set in the environment.
3. **A `log` function** prints each message with a timestamp and appends it to the log file (`tee -a`).
4. **Data collection:**
   - Disk: `df` prints the usage percentage, and `tr -dc '0-9'` strips everything except the digits.
   - Memory: `awk` calculates `(total - available) / total * 100` from the `free` output.
   - Load: `cut` takes the first field of `/proc/loadavg`.
5. **Checks:** disk and memory are compared as integers with `-ge`. Load is a decimal number, which Bash can't compare natively, so `awk` does that comparison.

### Testing

| Test | Command | Expected result | Result |
|---|---|---|---|
| Normal run | `./monitor.sh` | One `STATUS` line, no alerts | [pass/fail] |
| Forced alerts | `DISK_LIMIT=1 MEM_LIMIT=1 ./monitor.sh` | `STATUS` line plus disk and memory `ALERT` lines | [pass/fail] |
| Load alert | `LOAD_LIMIT=0.0 ./monitor.sh` | `STATUS` line plus a load `ALERT` line | [pass/fail] |
| Real disk alert | Fill the disk past the threshold with a large temporary file, run the script, then delete the file | Disk `ALERT` line | [pass/fail] |

### Limitations

- Alerts are only written to the log. There is no email or push notification yet.
- It only reports the root filesystem, not other mounted drives.
- It reports a single snapshot, so it needs to be scheduled (see `04-automation/`) to build a history.
- Thresholds are fixed values and aren't tuned to the machine's normal behaviour.
