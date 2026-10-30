#!/usr/bin/env bash
# Install local git hooks for this clone (not committed into .git).
set -euo pipefail

cd "$(dirname "$0")/.."
HOOK_SRC="$(pwd)/scripts/git-hooks/pre-push"
HOOK_DST="$(git rev-parse --git-dir)/hooks/pre-push"

mkdir -p "$(dirname "$HOOK_DST")"
ln -sfn "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_SRC" "$HOOK_DST" 2>/dev/null || chmod +x "$HOOK_SRC"

echo "Installed pre-push hook → $HOOK_DST"
echo "On push to master/main it will ask whether to bump the theme version."
echo "Skip once: SKIP_VERSION_BUMP_PROMPT=1 git push"
