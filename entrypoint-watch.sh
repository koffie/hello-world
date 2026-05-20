#!/usr/bin/env bash
set -euo pipefail

WATCH_DIR=/project/content/tex

echo "Watcher: watching $WATCH_DIR for .tex changes..."

while inotifywait -r -e close_write,moved_to,create --include '.*\.tex' "$WATCH_DIR"; do
  echo "Watcher: change detected, rebuilding..."
  if /app/build.sh; then
    echo "Watcher: rebuild complete — refresh your browser"
  else
    echo "Watcher: rebuild failed, check output above"
  fi
done
