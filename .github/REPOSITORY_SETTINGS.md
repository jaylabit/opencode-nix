# Repository Settings Configuration

This repository requires specific GitHub settings to enable automated update pull requests.

## Required Settings

### GitHub Actions Permissions

1. Navigate to Settings -> Actions -> General.
2. Under "Workflow permissions":
   - Select **Read and write permissions**.
   - Check **Allow GitHub Actions to create and approve pull requests**.
3. Click Save.

### Auto-merge

1. Navigate to Settings -> General.
2. Under "Pull Requests", check **Allow auto-merge**.
3. Click Save.

These settings allow `update-opencode.yml` to create update pull requests and enable auto-merge after CI passes.

## Verification

```bash
gh workflow run "Update OpenCode Version"
gh run list --workflow="Update OpenCode Version"
```
