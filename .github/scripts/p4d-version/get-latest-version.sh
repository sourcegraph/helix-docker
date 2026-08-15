#!/usr/bin/env bash
# Downloads the Perforce APT "Packages" index and extracts the latest
# available helix-p4d version, exposed as the "version" step output.
set -euo pipefail

PACKAGES_URL="https://package.perforce.com/apt/ubuntu/dists/noble/release/binary-amd64/Packages"

TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT

curl -fsSL "$PACKAGES_URL" -o "$TMP_FILE"

# Debian control file format: records are separated by a blank line.
# We keep records where "Package: helix-p4d" is an exact match (so
# "helix-p4d-doc" etc. are excluded), then read their Version field.
# If several versions are listed, keep the highest one (version sort).
LATEST_VERSION=$(awk -v RS='' -F'\n' '
  {
    pkg=""; ver="";
    for (i = 1; i <= NF; i++) {
      if ($i == "Package: helix-p4d") pkg=$i;
      if ($i ~ /^Version: /) { ver=$i; sub(/^Version: /, "", ver) }
    }
    if (pkg != "") print ver
  }
' "$TMP_FILE" | sort -V | tail -1)

if [[ -z "$LATEST_VERSION" ]]; then
  echo "Could not find the helix-p4d package in the Perforce feed" >&2
  exit 1
fi

echo "version=$LATEST_VERSION" >> "$GITHUB_OUTPUT"
echo "Latest available version: $LATEST_VERSION"
