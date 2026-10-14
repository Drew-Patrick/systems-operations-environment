#!/usr/bin/env bash
set -euo pipefail

SRC=/srv/data/
DEST=backup:/srv/backup/

echo "backup: start $(date -u +%FT%TZ)"
USED=$(ssh backup "df --output=pcent /srv/backup | tail -1 | tr -dc '0-9'")
if [ "$USED" -ge 90 ]; then
  echo "backup: ABORT, destination is ${USED}% full" >&2
  exit 1
fi
rsync -a "$SRC" "$DEST"
echo "backup: ok $(date -u +%FT%TZ)"