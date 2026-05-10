#!/usr/bin/env bash
set -euo pipefail

echo "Configuring GitHub repository settings..."

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

cat << EOF

================================================================
MANUAL CONFIGURATION REQUIRED
================================================================

To complete setup, configure the following in GitHub:

1. Go to: https://github.com/$REPO/settings/actions
2. Under "Workflow permissions":
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"
3. Go to: https://github.com/$REPO/settings
4. Under "Pull Requests", check "Allow auto-merge"

After completing these steps, test the workflow with:
  gh workflow run "Update OpenCode Version"

EOF
