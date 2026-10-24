#!/usr/bin/env bash
# Copies the mod's scripts into the game's r6/scripts folder.
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)/src/KromSetleri"
DEST="/d/SteamLibrary/steamapps/common/Cyberpunk 2077/r6/scripts/KromSetleri"
if tasklist | grep -qi Cyberpunk2077; then
  echo "Game is running; close it before deploying." >&2
  exit 1
fi
rm -rf "$DEST"
mkdir -p "$DEST"
cp "$SRC"/*.reds "$DEST"/
echo "Deployed: $(ls "$DEST" | tr '\n' ' ')"
