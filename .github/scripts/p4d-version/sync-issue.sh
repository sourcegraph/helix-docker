#!/usr/bin/env bash
# Creates (or updates) a GitHub issue tracking the fact that a newer
# helix-p4d version is available than the one pinned in the Dockerfile.
#
# Requires the following environment variables:
#   GH_TOKEN         - token used by the gh CLI
#   REPO             - "owner/repo"
#   CURRENT_VERSION  - version currently pinned in the Dockerfile
#   LATEST_VERSION   - version currently available from Perforce
set -euo pipefail

: "${GH_TOKEN:?GH_TOKEN is required}"
: "${REPO:?REPO is required}"
: "${CURRENT_VERSION:?CURRENT_VERSION is required}"
: "${LATEST_VERSION:?LATEST_VERSION is required}"

LABEL="p4d-update"

# Make sure the label exists (no-op if it already does)
gh label create "$LABEL" \
  --color "FBCA04" \
  --description "A newer helix-p4d version is available from Perforce" \
  --force || true

# Look for an already-open issue carrying this label
EXISTING_ISSUE=$(gh issue list \
  --repo "$REPO" \
  --label "$LABEL" \
  --state open \
  --json number,title,body \
  --jq '.[0]')

if [[ -z "$EXISTING_ISSUE" || "$EXISTING_ISSUE" == "null" ]]; then
  echo "No open issue found, creating a new one."
  ISSUE_BODY=$(printf '%s\n' \
    "A newer version of the \`helix-p4d\` package is available from the Perforce repository." \
    "" \
    "- Version currently pinned in \`helix-p4d/Dockerfile\`: \`$CURRENT_VERSION\`" \
    "- Available version: \`$LATEST_VERSION\`" \
    "" \
    "The \`apt-get install\` line in the Dockerfile should be updated accordingly (also double-check the \`helix-swarm-triggers\` version if relevant)." \
    "" \
    "Source: https://package.perforce.com/apt/ubuntu/dists/noble/release/binary-amd64/Packages" \
    "" \
    "_This issue was created automatically by the \`check-p4d-version.yml\` workflow._")

  gh issue create \
    --repo "$REPO" \
    --title "helix-p4d: newer version available ($LATEST_VERSION)" \
    --label "$LABEL" \
    --body "$ISSUE_BODY"
  exit 0
fi

ISSUE_NUMBER=$(echo "$EXISTING_ISSUE" | jq -r '.number')
ISSUE_TEXT=$(echo "$EXISTING_ISSUE" | jq -r '.title + "\n" + .body')

# Also check existing comments so the same version isn't posted twice
ALREADY_MENTIONED=$(gh issue view "$ISSUE_NUMBER" --repo "$REPO" --json comments --jq '.comments[].body' | grep -F "$LATEST_VERSION" || true)

if echo "$ISSUE_TEXT" | grep -qF "$LATEST_VERSION" || [[ -n "$ALREADY_MENTIONED" ]]; then
  echo "Version $LATEST_VERSION is already mentioned on issue #$ISSUE_NUMBER, nothing to do."
  exit 0
fi

echo "Issue #$ISSUE_NUMBER is already open for an earlier version, adding a comment."
gh issue comment "$ISSUE_NUMBER" \
  --repo "$REPO" \
  --body "Update: an even newer version is now available: \`$LATEST_VERSION\` (currently pinned version: \`$CURRENT_VERSION\`)."
