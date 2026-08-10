#!/bin/bash
# Launch the macOS debug build in a way that keeps its Local Network access.
#
# macOS grants that permission against the app's code SIGNATURE, and
# `flutter run` re-signs the bundle ad-hoc on every build — which silently
# revokes it, so discovery finds the gateway and nothing else. Re-signing
# with a stable Developer identity keeps the grant, and launching the binary
# directly (rather than through the flutter tool) keeps stdout where you can
# read it.
#
# Usage: tool/run_signed.sh [--build]   (--build recompiles first)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/build/macos/Build/Products/Debug/Vidra.app"
LOG="${VIDRA_LOG:-/tmp/vidra-cast.log}"
IDENTITY="${VIDRA_SIGN_IDENTITY:-Apple Development: twilight moon (MGPC47SJ6X)}"

if [[ "${1:-}" == "--build" ]]; then
  (cd "$ROOT" && flutter build macos --debug)
fi

[[ -d "$APP" ]] || { echo "no build at $APP — run with --build"; exit 1; }

ENTS="$(mktemp -t vidra-ents).plist"
codesign -d --entitlements "$ENTS" --xml "$APP" 2>/dev/null
codesign --force --deep --sign "$IDENTITY" --entitlements "$ENTS" "$APP"
echo "signed as: $(codesign -dv "$APP" 2>&1 | grep TeamIdentifier)"

pkill -x Vidra 2>/dev/null || true
sleep 1
echo "logging to $LOG"
exec "$APP/Contents/MacOS/Vidra" >"$LOG" 2>&1
