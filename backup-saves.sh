#!/usr/bin/env bash
# Copies all Cyberpunk 2077 saves into a timestamped backup folder.
set -euo pipefail
SAVES="/c/Users/merci/Saved Games/CD Projekt Red/Cyberpunk 2077"
DEST="/c/Users/merci/cp2077-build/original-backup/saves-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEST"
cp -r "$SAVES"/. "$DEST"/
echo "Saves backed up to $DEST ($(du -sh "$DEST" | cut -f1))"
