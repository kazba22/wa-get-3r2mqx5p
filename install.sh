#!/usr/bin/env bash
# Work Agent Starter Pack installer (Mac and Linux).
# What this does: downloads the pack and unpacks it into ~/Documents/WorkAgent/pack.
# What it does NOT do: no sudo, no changes outside that folder, no accounts touched.
# Read it before you run it. It is plain text.
set -euo pipefail

BASE="${WORKAGENT_BASE_URL:-https://kazba22.github.io/wa-get-3r2mqx5p}"
DEST="${WORKAGENT_DIR:-$HOME/Documents/WorkAgent}"
CODE="${WORKAGENT_CODE:-}"

if [ -n "$CODE" ]; then URL="$BASE/p/$CODE/pack.zip"; VURL="$BASE/p/$CODE/version.txt"; else URL="$BASE/pack.zip"; VURL="$BASE/version.txt"; fi

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing tool: $1. Please install it and run again."; exit 1; }; }
need curl

# Unpack a zip with whatever the computer has: unzip, bsdtar (Mac), or python3.
extract() {
  if command -v unzip >/dev/null 2>&1; then unzip -q "$1" -d "$2"
  elif tar --version 2>/dev/null | grep -qi bsdtar; then tar -xf "$1" -C "$2"
  elif command -v python3 >/dev/null 2>&1; then python3 -m zipfile -e "$1" "$2"
  else echo "I need unzip or python3 to unpack the download. Please install one and run again."; exit 1
  fi
}

echo "Work Agent Starter Pack"
echo "Installing into: $DEST"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if ! curl -fsSL "$URL" -o "$TMP/pack.zip"; then
  echo "Download failed. Check your internet connection and your access code (if you were given one)."
  exit 1
fi
if command -v unzip >/dev/null 2>&1; then
  unzip -tq "$TMP/pack.zip" >/dev/null || { echo "The download is damaged. Run the command again."; exit 1; }
fi

mkdir -p "$DEST"
# Keep the user's own files. Only the pack folder is replaced on update.
OLD_VERSION=""
[ -f "$DEST/pack/VERSION" ] && OLD_VERSION="$(cat "$DEST/pack/VERSION")"
rm -rf "$DEST/pack.new"
mkdir -p "$DEST/pack.new"
extract "$TMP/pack.zip" "$DEST/pack.new"
rm -rf "$DEST/pack"
mv "$DEST/pack.new" "$DEST/pack"
mkdir -p "$DEST/profile"

NEW_VERSION="$(cat "$DEST/pack/VERSION" 2>/dev/null || echo unknown)"
if [ -n "$OLD_VERSION" ]; then echo "Updated: $OLD_VERSION -> $NEW_VERSION (your profile folder was not touched)"; else echo "Installed version: $NEW_VERSION"; fi

START="$DEST/pack/onboarding/AGENT-START.md"
[ -f "$START" ] || { echo "Something is wrong: $START is missing."; exit 1; }

cat <<EOF

Done. Last step: open Aside, start a new task, and paste this:

Read the file $START and follow it exactly. Ask me to approve access to the folder $DEST if needed. Do not send any message or change any account.

(Do not have Aside yet? Install it from aside.com/download and connect your Claude subscription in Settings > Models > Providers first. See $DEST/pack/onboarding/1-student-quickstart.md)
EOF
