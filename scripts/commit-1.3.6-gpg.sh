#!/usr/bin/env bash
# One-shot segmented commits for Oreo 1.3.6 (GPG-signed).
# Run from the repo root after unlocking your GPG key / keychain:
#   chmod +x scripts/commit-1.3.6-gpg.sh && ./scripts/commit-1.3.6-gpg.sh
#
# Optional: push + tag when done
#   PUSH=1 ./scripts/commit-1.3.6-gpg.sh

set -euo pipefail

cd "$(dirname "$0")/.."

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository" >&2
  exit 1
fi

echo "==> Checking GPG signing works..."
if ! (echo "oreo-gpg-probe" | gpg --clearsign >/dev/null 2>&1); then
  echo "GPG signing failed. Unlock your keychain / pinentry, then re-run." >&2
  echo "Tip (in Terminal.app):  echo test | gpg --clearsign" >&2
  exit 1
fi

commit_paths() {
  local message=$1
  shift
  git add -- "$@"
  # Skip empty commits if nothing staged for these paths
  if git diff --cached --quiet; then
    echo "skip (no changes): $message"
    return 0
  fi
  git commit -m "$message"
  echo "committed: $message"
}

echo "==> 1/6 Theme bugfixes + palette"
commit_paths "$(cat <<'EOF'
Fix theme bugs and soften Oreo palette

Wire code Style Settings to real --code-* variables, enable alternative
checkboxes by default, repair tab option/animation wiring and depth-tab
dark mode, and replace neon accents with cream/cocoa tones.
EOF
)" theme.css

echo "==> 2/6 Style Settings presets"
commit_paths "$(cat <<'EOF'
Replace Style Settings defaults with Oreo-native preset

Remove the copied Things/Minimal keys and add an Oreo starter JSON plus
a short folder readme.
EOF
)" \
  plugins/Style-Settings/style-settings-default.json \
  plugins/Style-Settings/README.md \
  plugins/Style-Settings/placeholder.txt

echo "==> 3/6 Release workflow"
commit_paths "$(cat <<'EOF'
Modernize theme release GitHub Action

Use gh release create so tagged versions upload manifest.json and
theme.css reliably.
EOF
)" \
  .github/workflows/release.yml \
  .github/workflows/release-version.yml

echo "==> 4/6 Docs"
commit_paths "$(cat <<'EOF'
Update READMEs for checkboxes, tabs, and customization flow

Drop broken TOC anchors and document default checkboxes plus corrected
tab style options.
EOF
)" README.md README_CN.md

echo "==> 5/6 Version bump"
commit_paths "$(cat <<'EOF'
Bump version to 1.3.6

Sync package.json with manifest.json and record 1.3.6 in versions.json.
EOF
)" manifest.json package.json versions.json

echo "==> 6/6 Commit helper script"
commit_paths "$(cat <<'EOF'
Add GPG-friendly segmented release commit script

One-shot helper used to land the 1.3.6 fix series with signed commits.
EOF
)" scripts/commit-1.3.6-gpg.sh

echo
echo "Done. Recent commits:"
git log --oneline -8

if [[ "${PUSH:-0}" == "1" ]]; then
  echo "==> Pushing master..."
  git push origin HEAD:master
  echo "==> Creating annotated tag 1.3.6..."
  git tag -s 1.3.6 -m "Oreo 1.3.6" 2>/dev/null || git tag -a 1.3.6 -m "Oreo 1.3.6"
  git push origin 1.3.6
  echo "Pushed tag 1.3.6 (release workflow should attach assets)."
else
  echo
  echo "Next (when ready):"
  echo "  git push origin HEAD:master"
  echo "  git tag -s 1.3.6 -m 'Oreo 1.3.6' && git push origin 1.3.6"
  echo "Or re-run with:  PUSH=1 ./scripts/commit-1.3.6-gpg.sh"
fi
