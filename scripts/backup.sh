#!/usr/bin/env bash
set -euo pipefail

SRC=/srv/data/
DEST=backup:/srv/backup/

echo "backup: start $(date -u +%FT%TZ)"
rsync -a "$SRC" "$DEST"
echo "backup: ok $(date -u +%FT%TZ)"