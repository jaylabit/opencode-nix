# AGENTS.md

Guide for coding agents working in this repository.

## Repository purpose

`opencode-nix` is a small standalone flake that packages the official
`anomalyco/opencode` stable release archives for Linux and macOS.

The repository is intentionally narrow:

- expose `opencode` as a flake package, app, and overlay
- pin the packaged upstream version and hashes in `sources.json`
- automate version bumps with `scripts/update-version.sh`
- build/test in GitHub Actions
- tag only packaged releases

## Top-level layout

- `flake.nix` / `flake.lock` - flake entrypoint and locked inputs
- `package.nix` - derivation for the `opencode` binary
- `sources.json` - source of truth for packaged version and per-platform hashes
- `scripts/update-version.sh` - updates `sources.json`, refreshes `flake.lock`, verifies build
- `scripts/setup-github-permissions.sh` - helper text for required GitHub settings
- `.github/workflows/build.yml` - CI build and smoke test
- `.github/workflows/update-opencode.yml` - scheduled/manual update PR workflow
- `.github/workflows/create-version-tag.yml` - creates exact and moving tags for new packaged releases
- `.github/dependabot.yml` - weekly GitHub Actions dependency updates
- `README.md` - user-facing docs

## Repository conventions

### Flake / package model

- `flake.nix` exposes:
  - `packages.default`
  - `packages.opencode`
  - `apps.default`
  - `apps.opencode`
  - `overlays.default`
- `package.nix` must keep `sources.json` as the only version/hash source.
- The installed program name is `opencode`.

### Release metadata

- `sources.json` is the canonical place for:
  - packaged upstream version
  - asset name per supported system
  - fixed SRI hash per supported system
- Supported systems are currently:
  - `x86_64-linux`
  - `aarch64-linux`
  - `x86_64-darwin`
  - `aarch64-darwin`
- Asset names follow upstream stable release naming:
  - `opencode-linux-x64.tar.gz`
  - `opencode-linux-arm64.tar.gz`
  - `opencode-darwin-x64.zip`
  - `opencode-darwin-arm64.zip`

### Update flow

- Prefer `./scripts/update-version.sh` over manual edits when bumping versions.
- The update script:
  - discovers the latest upstream release
  - prefetches stable release assets with Nix
  - rewrites `sources.json`
  - runs `nix flake update`
  - verifies with `nix build .#opencode` and `./result/bin/opencode --version`
- Keep the script simple and shell-only; do not add extra tooling unless necessary.

### GitHub Actions behavior

- `build.yml` is the main CI surface and should keep building on Ubuntu and macOS.
- `update-opencode.yml` should only open a PR when the packaged version actually changes.
- `create-version-tag.yml` should:
  - create exact tag `vX.Y.Z` for new packaged versions
  - move `vX` and `latest` only when a new exact version is created
  - leave moving tags untouched if the packaged version is unchanged
- Do not add Cachix or other binary-cache assumptions unless explicitly requested.

### Documentation

- Update `README.md` when changing:
  - user installation flow
  - flake outputs
  - update automation
  - tag semantics
  - trust/security behavior
- Keep README examples valid for this repo; do not leave copied references to other projects.

## Safe change guide

1. Prefer small changes in the existing files over adding new abstraction layers.
2. Keep `sources.json` machine-editable and stable in shape.
3. Do not rename the `opencode` executable or change public flake outputs unless the user asks.
4. Do not rewrite workflow behavior around tagging/update cadence without also updating README docs.
5. Do not manually retag `v1` / `latest` for dependency-only changes when the packaged OpenCode version is unchanged.
6. Do not introduce secrets into the repository; workflows rely on GitHub-provided tokens/settings.

## Validation commands

Use the smallest relevant validation set for the change:

- docs only:
  - `git diff --check`
- shell/workflow/docs changes:
  - `bash -n scripts/*.sh`
  - `git diff --check`
- package/update changes:
  - `nix flake check --print-build-logs`
  - `nix build .#opencode -o result --print-build-logs`
  - `./result/bin/opencode --version`
- updater changes:
  - `./scripts/update-version.sh --latest-version`
  - `./scripts/update-version.sh --check`

## GitHub repository settings

Automated update PRs require repository settings that allow Actions to:

- use `GITHUB_TOKEN` with read/write permissions
- create pull requests
- use auto-merge if that workflow step is enabled

See `.github/REPOSITORY_SETTINGS.md` when working on update automation.
