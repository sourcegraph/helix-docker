#!/usr/bin/env bash
# Reads the helix-p4d version pinned in the Dockerfile at the current
# commit (main), looks at existing git tags to find the next available
# release number (rX), then creates and pushes an immutable annotated
# tag "<perforce_version>-rX" pointing at the current commit.
#
# This tag is what triggers the actual build+push workflow (release.yml).
# Because each rX gets its own dedicated, never-moved git tag, it is
# always possible to trace back which exact commit a given release was
# built from, e.g. `git show 2026.1-2972966-r1`.
set -euo pipefail

DOCKERFILE="helix-p4d/Dockerfile"

PERFORCE_VERSION=$(grep -oP 'helix-p4d=\K[^ \\]+' "$DOCKERFILE" | head -1 | sed 's/~.*//')
if [[ -z "$PERFORCE_VERSION" ]]; then
  echo "Could not find a pinned helix-p4d version in $DOCKERFILE" >&2
  exit 1
fi
echo "Perforce version pinned in Dockerfile: $PERFORCE_VERSION"

git fetch origin --tags --force

LAST_R=$( (git tag -l "${PERFORCE_VERSION}-r*" \
  | grep -E "^${PERFORCE_VERSION}-r[0-9]+$" \
  | sed -E "s/^${PERFORCE_VERSION}-r([0-9]+)$/\1/" \
  | sort -n | tail -1) || true)

if [[ -z "$LAST_R" ]]; then
  NEXT_R=1
else
  NEXT_R=$((LAST_R + 1))
fi

NEW_TAG="${PERFORCE_VERSION}-r${NEXT_R}"
echo "Next release tag: $NEW_TAG"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git tag -a "$NEW_TAG" -m "Release $NEW_TAG"
git push origin "$NEW_TAG"

echo "tag=$NEW_TAG" >> "$GITHUB_OUTPUT"
echo "Pushed tag $NEW_TAG. Triggering the release workflow explicitly next."
