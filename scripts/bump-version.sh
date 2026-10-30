#!/usr/bin/env bash
# Bump Oreo theme version across package.json / manifest.json / versions.json.
#
# Usage:
#   ./scripts/bump-version.sh                 # interactive: patch / minor / major
#   ./scripts/bump-version.sh patch
#   ./scripts/bump-version.sh minor
#   ./scripts/bump-version.sh major
#   ./scripts/bump-version.sh 1.4.0
#   ./scripts/bump-version.sh patch --commit
#   ./scripts/bump-version.sh patch --tag       # commit + tag (no "v" prefix)
#   ./scripts/bump-version.sh patch --tag --push
#
# Env (same as flags):
#   COMMIT=1  TAG=1  PUSH=1
#
# Notes:
#   - Obsidian community releases require the git tag to match manifest.version
#     exactly (e.g. 1.4.0), with no "v" prefix.
#   - --tag implies --commit. --push implies --tag.

set -euo pipefail

cd "$(dirname "$0")/.."

CURRENT=$(node -p "require('./package.json').version")
IFS=. read -r MAJOR MINOR PATCH <<<"${CURRENT%%-*}"

bump_kind=""
do_commit=0
do_tag=0
do_push=0

for arg in "$@"; do
  case "$arg" in
    --commit) do_commit=1 ;;
    --tag) do_tag=1; do_commit=1 ;;
    --push) do_push=1; do_tag=1; do_commit=1 ;;
    -*)
      echo "Unknown flag: $arg" >&2
      exit 1
      ;;
    *)
      if [[ -z "$bump_kind" ]]; then
        bump_kind="$arg"
      else
        echo "Unexpected argument: $arg" >&2
        exit 1
      fi
      ;;
  esac
done

[[ "${COMMIT:-0}" == "1" ]] && do_commit=1
if [[ "${TAG:-0}" == "1" ]]; then
  do_tag=1
  do_commit=1
fi
if [[ "${PUSH:-0}" == "1" ]]; then
  do_push=1
  do_tag=1
  do_commit=1
fi

if [[ -z "$bump_kind" ]]; then
  if [[ ! -t 0 ]]; then
    echo "Non-interactive shell: pass patch|minor|major|x.y.z" >&2
    exit 1
  fi
  echo "Current version: $CURRENT"
  echo "Bump type? [patch/minor/major] (default: patch)"
  read -r bump_kind
  bump_kind=${bump_kind:-patch}
fi

case "$bump_kind" in
  patch) NEXT="$MAJOR.$MINOR.$((PATCH + 1))" ;;
  minor) NEXT="$MAJOR.$((MINOR + 1)).0" ;;
  major) NEXT="$((MAJOR + 1)).0.0" ;;
  *)
    if [[ "$bump_kind" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]]; then
      NEXT="$bump_kind"
    else
      echo "Unknown bump kind: $bump_kind (use patch|minor|major|x.y.z)" >&2
      exit 1
    fi
    ;;
esac

if [[ "$NEXT" == "$CURRENT" ]]; then
  echo "Already at $CURRENT"
  exit 0
fi

if [[ "$do_tag" == "1" ]] && git rev-parse -q --verify "refs/tags/$NEXT" >/dev/null; then
  echo "Tag $NEXT already exists locally. Delete it first or choose another version." >&2
  exit 1
fi

node version-bump.mjs "$NEXT"
echo "$CURRENT → $NEXT"

if [[ "$do_commit" == "1" ]]; then
  git add package.json manifest.json versions.json
  if git diff --cached --quiet; then
    echo "Nothing to commit (files already match $NEXT)"
  else
    git commit -m "$(cat <<EOF
Bump version to $NEXT

EOF
)"
    echo "Committed version bump $NEXT"
  fi
fi

if [[ "$do_tag" == "1" ]]; then
  # Exact manifest version, no "v" prefix — required by Obsidian.
  if git config --get user.signingkey >/dev/null 2>&1 || [[ "$(git config --get tag.gpgSign 2>/dev/null || true)" == "true" ]]; then
    git tag -s "$NEXT" -m "Oreo $NEXT" 2>/dev/null || git tag -a "$NEXT" -m "Oreo $NEXT"
  else
    git tag -a "$NEXT" -m "Oreo $NEXT"
  fi
  echo "Tagged $NEXT"
fi

if [[ "$do_push" == "1" ]]; then
  branch=$(git rev-parse --abbrev-ref HEAD)
  git push origin "HEAD:refs/heads/$branch"
  git push origin "refs/tags/$NEXT"
  echo "Pushed $branch and tag $NEXT (release Action should run)"
fi
