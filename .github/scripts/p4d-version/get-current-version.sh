#!/usr/bin/env bash
# Extracts the helix-p4d version currently pinned in helix-p4d/Dockerfile
# and exposes it as the "version" step output.
set -euo pipefail

DOCKERFILE="helix-p4d/Dockerfile"

VERSION=$(grep -oP 'helix-p4d=\K[^ \\]+' "$DOCKERFILE" | head -1)

if [[ -z "$VERSION" ]]; then
  echo "Could not find a pinned helix-p4d version in $DOCKERFILE" >&2
  exit 1
fi

echo "version=$VERSION" >> "$GITHUB_OUTPUT"
echo "Currently pinned version: $VERSION"
