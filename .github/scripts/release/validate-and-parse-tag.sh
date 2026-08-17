#!/usr/bin/env bash
# Validates the git tag that triggered this workflow (normally created by
# the "Create Release Tag" workflow) and extracts version info from it.
# Expected format: <year>.<release>-<build>-r<N>, e.g. 2026.1-2972966-r2
#
# Also checks, as defense in depth in case a tag was ever pushed manually
# instead of through the "Create Release Tag" workflow:
#   - the tagged commit is an ancestor of main
#   - the Perforce version embedded in the tag matches what's pinned in
#     the Dockerfile at that commit
#
# Exposes: perforce_version, short_version, release_number, image_name,
# tags (multiline list of docker tags to build & push)
set -euo pipefail

TAG="${GITHUB_REF_NAME:?GITHUB_REF_NAME is required}"
DOCKERFILE="helix-p4d/Dockerfile"

if [[ ! "$TAG" =~ ^(([0-9]{4}\.[0-9]+)-([0-9]+))-r([0-9]+)$ ]]; then
  echo "Tag '$TAG' does not match the expected <year>.<release>-<build>-r<N> format (e.g. 2026.1-2972966-r2)" >&2
  exit 1
fi

PERFORCE_VERSION="${BASH_REMATCH[1]}"
SHORT_VERSION="${BASH_REMATCH[2]}"
RELEASE_NUMBER="${BASH_REMATCH[4]}"

echo "Tag: $TAG"
echo "Perforce version: $PERFORCE_VERSION"
echo "Short version: $SHORT_VERSION"
echo "Release number: r$RELEASE_NUMBER"

if ! git merge-base --is-ancestor "$GITHUB_SHA" origin/main; then
  echo "Commit $GITHUB_SHA (tag $TAG) is not an ancestor of main. Refusing to publish." >&2
  exit 1
fi

DOCKERFILE_VERSION=$(grep -oP 'helix-p4d=\K[^ \\]+' "$DOCKERFILE" | head -1 | sed 's/~.*//')
if [[ "$DOCKERFILE_VERSION" != "$PERFORCE_VERSION" ]]; then
  echo "Tag ($PERFORCE_VERSION) does not match the version pinned in $DOCKERFILE at this commit ($DOCKERFILE_VERSION)" >&2
  exit 1
fi

OWNER_LOWER=$(echo "${GITHUB_REPOSITORY_OWNER}" | tr '[:upper:]' '[:lower:]')
IMAGE_NAME="ghcr.io/${OWNER_LOWER}/helix-p4d"
CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)

{
  echo "perforce_version=$PERFORCE_VERSION"
  echo "short_version=$SHORT_VERSION"
  echo "release_number=$RELEASE_NUMBER"
  echo "image_name=$IMAGE_NAME"
  echo "created=$CREATED"
  echo "tags<<TAGS_EOF"
  echo "${IMAGE_NAME}:${TAG}"
  echo "${IMAGE_NAME}:latest"
  echo "${IMAGE_NAME}:${SHORT_VERSION}"
  echo "TAGS_EOF"
} >> "$GITHUB_OUTPUT"
