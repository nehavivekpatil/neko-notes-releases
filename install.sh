#!/bin/bash
# Installs (or updates) Neko Notes from the latest GitHub release.
#
#   curl -fsSL https://raw.githubusercontent.com/nehavivekpatil/neko-notes-releases/main/install.sh | bash
#
# Downloading with curl means macOS doesn't mark the app as "downloaded from the internet",
# so it opens without the "Open Anyway" step. Your notes are kept when updating.
set -euo pipefail

REPO="nehavivekpatil/neko-notes-releases"
APP="Neko Notes.app"
DEST="${NEKO_DEST:-/Applications}"   # NEKO_DEST / NEKO_NO_OPEN are only for testing

say()  { printf '\033[1;35m🐱 %s\033[0m\n' "$1"; }
fail() { printf '\033[1;31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

[ "$(uname)" = "Darwin" ] || fail "Neko Notes only runs on macOS."
version=$(sw_vers -productVersion)
[ "${version%%.*}" -ge 14 ] || fail "Neko Notes needs macOS 14 Sonoma or later. This Mac has macOS $version."

say "Finding the latest Neko Notes…"
url=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | sed -n 's/.*"browser_download_url": *"\([^"]*\.dmg\)".*/\1/p' | sed -n 1p)
[ -n "$url" ] || fail "Couldn't find the download. Check your internet connection and try again."

tmp=$(mktemp -d)
cleanup() { hdiutil detach "$tmp/disk" -quiet 2>/dev/null || true; rm -rf "$tmp"; }
trap cleanup EXIT

say "Downloading ${url##*/}…"
curl -fL --progress-bar -o "$tmp/NekoNotes.dmg" "$url"

hdiutil attach -nobrowse -readonly -noautoopen -mountpoint "$tmp/disk" "$tmp/NekoNotes.dmg" -quiet \
  || fail "Couldn't open the downloaded file. Please try again."

if [ ! -w "$DEST" ]; then
  DEST="$HOME/Applications"
  mkdir -p "$DEST"
fi

if pgrep -x NekoNotes >/dev/null; then
  say "Closing Neko Notes to update it (your notes are safe)…"
  pkill -x NekoNotes || true
  sleep 1
fi

say "Installing into $DEST…"
rm -rf "${DEST:?}/$APP"
ditto "$tmp/disk/$APP" "$DEST/$APP"
xattr -dr com.apple.quarantine "$DEST/$APP" 2>/dev/null || true

if [ -z "${NEKO_NO_OPEN:-}" ]; then
  open "$DEST/$APP"
fi
say "Done! Mishu is waiting for you on your desktop 🐾"
