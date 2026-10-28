# 04-automation: scheduling with cron

This folder holds the schedule that runs the scripts in [`../03-scripts/`](../03-scripts/) automatically, so backups and health checks happen without anyone logging in.

| File | Purpose |
|---|---|
| [`crontab.txt`](crontab.txt) | Export of the server's crontab (`crontab -l`) |

## Schedule

| Job | Script | Schedule | Cron expression |
|---|---|---|---|
| Health check | `monitor.sh` | Every 5 minutes | `*/5 * * * *` |
| Backup | `backup.sh` | Daily at 13:00 | `0 13 * * *` |

The crontab:

```
*/5 * * * * /home/<user>/scripts/monitor.sh > /dev/null 2>> /home/<user>/cron-errors.log
0 13 * * * /home/<user>/scripts/backup.sh > /dev/null 2>> /home/<user>/cron-errors.log
```

Replace `<user>` with the account name on your server.

### Why these times

- **Monitoring every 5 minutes** gives a useful history. Each run is tiny, and it adds about 288 log lines per day.
- **Backup once a day at 13:00** avoids needless writes to the spinning hard drive. The hour was chosen because the laptop is normally powered on then. A powered-off or suspended machine doesn't run cron jobs.

## How to read a cron line

```
*/5  *  *  *  *   /home/<user>/scripts/monitor.sh  > /dev/null  2>> /home/<user>/cron-errors.log
 |   |  |  |  |
 |   |  |  |  +-- day of week (0-7)
 |   |  |  +----- month (1-12)
 |   |  +-------- day of month (1-31)
 |   +----------- hour (0-23)
 +--------------- minute (0-59)
```

- `*` means "every", and `*/5` means "every 5th".
- **Full paths** are used because cron runs with a minimal environment and doesn't know your usual shell settings.
- `> /dev/null` discards normal output. The scripts already write their own timestamped logs, so the duplicate isn't needed.
- `2>> cron-errors.log` appends any error messages to a file, so a failure isn't lost silently.

## Setup

1. Confirm the cron service is running:
   ```bash
   systemctl status cron
   ```
   If it isn't active, start it with `sudo systemctl enable --now cron`.
2. Make sure the scripts exist and are executable:
   ```bash
   chmod +x ~/scripts/backup.sh ~/scripts/monitor.sh
   ```
3. Edit your crontab and add the two lines above:
   ```bash
   crontab -e
   ```
4. Confirm it was saved:
   ```bash
   crontab -l
   ```

To restore the schedule from this repo on a fresh machine, run `crontab crontab.txt`. This **replaces** the whole existing crontab, so check `crontab -l` first.

## How I tested it

I first used a fast test schedule to prove cron was firing, then switched to the realistic one.

| Stage | Schedule | Purpose |
|---|---|---|
| Test | `monitor.sh` every minute, `backup.sh` every 2 minutes | Confirm cron runs the scripts without anyone logged in |
| Production | `monitor.sh` every 5 minutes, `backup.sh` daily at 13:00 | Realistic schedule that avoids needless disk writes |

### Checks

```bash
tail -n 5 ~/monitor.log
tail -n 8 ~/backups/backup.log
ls -lh ~/backups
cat ~/cron-errors.log
journalctl -u cron -n 20
```

| Check | Expected result | Result |
|---|---|---|
| Monitor lines appear on schedule | A new `STATUS` line at each interval | [pass/fail] |
| Backup archives appear on schedule | A new archive at each interval | [pass/fail] |
| Error log | Empty or missing | [pass/fail] |
| Rotation under cron | No more than 7 archives after many runs | [pass/fail] |
| Survives a reboot | Jobs resume after restarting the laptop | [pass/fail] |

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Nothing appears in the logs | Cron isn't running (`systemctl status cron`), or the machine was asleep or off at the scheduled time |
| `Permission denied` in `cron-errors.log` | A script isn't executable (`chmod +x`) |
| `command not found` in `cron-errors.log` | A relative path or a command that needs the interactive shell's `PATH`. Use full paths |
| Script works by hand but not under cron | Cron's minimal environment. Use absolute paths for every file and command |
| `bad minute` or similar when saving the crontab | A typo in the five time fields |

## Limitations

- **Cron only runs while the machine is awake.** If the laptop is off or suspended at 13:00, that day's backup is skipped and not made up later. `anacron` or a systemd timer with `Persistent=true` would catch up on missed jobs.
- **Logs grow without limit.** `monitor.log` gains about 288 lines per day. This is small, but nothing trims it yet.
- **No notifications.** Alerts are only written to `monitor.log`, so someone has to read the file.
- **Backups still live on the same disk.** Scheduling makes them regular, but doesn't protect against drive failure.
- The laptop connects over a phone hotspot, which can drop, but these jobs are all local and don't depend on the network.

## Possible improvements

- Add `logrotate` rules for `monitor.log` and `backup.log`
- Replace cron with systemd timers (`Persistent=true`) so missed runs are made up
- Copy backups to another machine after each run
- Send an email or push message when `monitor.sh` records an `ALERT`
