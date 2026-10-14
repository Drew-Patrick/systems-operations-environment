# 007: backup fails with "No space left on device" on backup

**Date:** 2026-10-14 (UTC)
**Machine(s):** backup (symptom seen in app's backup job)
**Severity:** high (backups stop; the full disk is also the OS disk)

## Symptom
On app, `sudo systemctl start backup.service` reported
`Job for backup.service failed because the control process exited with error code.`
The journal showed `backup: start` with no `backup: ok`, then
`rsync: [receiver] write failed on "/srv/backup/big.bin": No space left on device (28)`,
`rsync error: error in file IO (code 11)`, `rsync: [sender] write error: Broken pipe (32)`,
and `backup.service: Main process exited, code=exited, status=11`.
Expected: `backup: ok`.
Cause of the break (planned): on backup, `fallocate` created `/srv/filler` sized to leave
about 2 MB free; on app, a 20 MB `big.bin` was added to `/srv/data`.

## Checked
- Journal on app: the first error is tagged `[receiver]`, so the failure is on the
  receiving side (backup), not on app. The sender's `Broken pipe` is a consequence.
- On backup: `df -h /srv` showed `/dev/sda2 61G 61G 2.0M 100% /`. The disk was full,
  and `/srv` is on `/`, the root filesystem, so the whole OS disk was full.
- On backup: `sudo du -sh /srv/*` showed `59G /srv/filler` and `0 /srv/backup`.
  One file accounted for the space.

## Cause
The destination filesystem on backup had no free space. rsync could not write the
incoming file, returned exit code 11 (file I/O error), and the script passed that code to
systemd.

## Fix
On backup: `sudo rm /srv/filler`. `df -h /srv` then showed 4% used, 59G available.

Preventive change: `scripts/backup.sh` now checks the destination before copying:

    USED=$(ssh backup "df --output=pcent /srv/backup | tail -1 | tr -dc '0-9'")
    if [ "$USED" -ge 90 ]; then
      echo "backup: ABORT, destination is ${USED}% full" >&2
      exit 1
    fi

## Verified
- On app, after clearing the filler: `sudo systemctl start backup.service` logged
  `backup: start`, `backup: ok`, `Finished backup.service`.
- Guard test: with the disk refilled, the job logged
  `backup: ABORT, destination is 100% full` and exited 1 with no rsync error. After
  clearing the filler again, a normal `backup: ok` run followed.

## Follow-up
Disk full: `df -h` to find which filesystem and how full, then `du -sh <dir>/*` to find
what is using it. Note which mount a path lives on; a full `/` affects everything on the
host, not just the one job. Jobs that write to a destination should check free space
first and refuse with a clear message rather than fail partway with a numeric code.