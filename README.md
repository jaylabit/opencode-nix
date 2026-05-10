# opencode-nix

Always up-to-date Nix package for the latest stable [OpenCode](https://github.com/anomalyco/opencode) CLI release from GitHub Releases.

**Automatically updated hourly** to keep this flake close to the latest stable OpenCode release.

## Acknowledgements

This repository follows the packaging approach from [jaylabit/github-copilot-nix](https://github.com/jaylabit/github-copilot-nix) by [@jaylabit](https://github.com/jaylabit).

That project is based on the packaging approach from [sadjow/claude-code-nix](https://github.com/sadjow/claude-code-nix) by [@sadjow](https://github.com/sadjow).

Related Nix package flakes from the same ecosystem:

- [jaylabit/github-copilot-nix](https://github.com/jaylabit/github-copilot-nix)
- [sadjow/claude-code-nix](https://github.com/sadjow/claude-code-nix)
- [sadjow/gemini-cli-nix](https://github.com/sadjow/gemini-cli-nix)
- [sadjow/codex-cli-nix](https://github.com/sadjow/codex-cli-nix)

## Why this package?

### Primary Goal: Latest Stable OpenCode for Nix Users

OpenCode already has several installation paths, including npm, Homebrew, Arch packages, nixpkgs, and the upstream repository flake. This flake exists for one narrow use case:

1. **Stable Release Artifacts**: Packages OpenCode's official GitHub release archives, not the upstream development branch.
2. **Immediate Updates**: New stable OpenCode releases are checked hourly.
3. **Flake-First Design**: Direct usage from NixOS, Home Manager, `nix profile`, and `nix run`.
4. **Native Binary Packaging**: Uses upstream native Linux and macOS CLI archives.
5. **Reproducible Pinning**: Version and per-platform fixed-output hashes are recorded in `sources.json`.

### Why Not Use the Upstream Flake?

OpenCode documents:

```bash
nix run nixpkgs#opencode           # or github:anomalyco/opencode for latest dev branch
```

`github:anomalyco/opencode` is useful when you intentionally want the latest development branch. This repository instead tracks the latest stable GitHub release and pins the exact downloaded artifacts.

### Why Not Use the Official Installer?

OpenCode's installer works well for imperative systems:

```bash
curl -fsSL https://opencode.ai/install | bash
```

For Nix users, installer-managed software has the usual limitations:

- **Not Declarative**: It is not managed by your NixOS or Home Manager configuration.
- **Harder to Pin**: Exact version pinning and rollback are manual.
- **Outside Nix**: The installed binary is not part of the Nix store.
- **Less Reproducible**: Installation depends on mutable external state at install time.

This flake keeps OpenCode in the Nix store with fixed-output hashes while still using OpenCode's official release artifacts.

### The Reality of nixpkgs Updates

If `opencode` is available and current in your nixpkgs revision, it is often the best default for broad community review. A dedicated flake is useful when you want a faster update cadence for stable releases:

- nixpkgs pull requests can take time to review and merge.
- updates depend on maintainer availability.
- you are tied to your nixpkgs channel's update schedule.
- urgent packaging changes can be delayed.

### This Repository's Approach

This repository provides:

- **Hourly Automated Checks**: GitHub Actions checks for new upstream stable releases.
- **Pinned Release Artifacts**: `package.nix` fetches GitHub release archives with fixed hashes.
- **Multi-Platform Support**: Linux and macOS, x86_64 and aarch64.
- **Simple Update Script**: `scripts/update-version.sh` prefetches release assets with Nix and updates `sources.json`.
- **Version Tags**: New packaged releases create `vX.Y.Z`, `vX`, and `latest` tags.

### Comparison Table

| Feature | Official installer | nixpkgs / upstream flake | This flake |
| --- | --- | --- | --- |
| Latest Stable Version | Usually latest | Can lag or track dev branch | Hourly checks |
| Declarative Config | No | Yes | Yes |
| Nix Store Package | No | Yes | Yes |
| Version Pinning | Manual | By nixpkgs or flake lock | Exact tags or commit SHAs |
| Rollback | Manual | Nix profile/system rollback | Nix profile/system rollback |
| Reproducible Fetches | No | Yes | Yes |
| Update Frequency | Immediate | Channel-dependent | Automated hourly check |
| Broad Review | OpenCode only | nixpkgs / upstream review | This repository |

## Quick Start

### Run without installing

```bash
nix run github:kubajanusz/opencode-nix
```

### Install to your profile

```bash
nix profile install github:kubajanusz/opencode-nix
```

### Verify installation

```bash
which opencode
opencode --version
```

## Standalone Installation

If you are not using NixOS or Home Manager, use `nix profile`.

### Install

```bash
nix profile install github:kubajanusz/opencode-nix
```

### Update

```bash
# Update all flake-based profile packages
nix profile upgrade --all

# Or update only OpenCode
nix profile upgrade '.*opencode.*'
```

### Rollback

```bash
nix profile rollback
```

### Uninstall

```bash
nix profile remove '.*opencode.*'
```

### Troubleshooting PATH

If `opencode` is not found after installation, ensure `~/.nix-profile/bin` is in your `PATH`:

```bash
echo "$PATH" | tr ':' '\n' | grep nix-profile
```

If it is missing, add this to your shell configuration:

```bash
export PATH="$HOME/.nix-profile/bin:$PATH"
```

For multi-user Nix installations, this is typically configured through `/etc/profile.d/nix.sh` or equivalent shell integration.

## Flake Usage

### Using the overlay

```nix
{
  nixpkgs.overlays = [ opencode-nix.overlays.default ];
  # pkgs.opencode is now available
}
```

### NixOS

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    opencode-nix.url = "github:kubajanusz/opencode-nix";
  };

  outputs = { nixpkgs, opencode-nix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ opencode-nix.overlays.default ];
          environment.systemPackages = [ pkgs.opencode ];
        })
      ];
    };
  };
}
```

### Home Manager

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    opencode-nix.url = "github:kubajanusz/opencode-nix";
  };

  outputs = { nixpkgs, home-manager, opencode-nix, ... }: {
    homeConfigurations."username" =
      let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ opencode-nix.overlays.default ];
        };
      in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          {
            home.packages = [ pkgs.opencode ];
          }
        ];
      };
  };
}
```

### Direct package reference

```nix
{
  inputs.opencode-nix.url = "github:kubajanusz/opencode-nix";

  outputs = { opencode-nix, ... }: {
    packages.x86_64-linux.my-opencode = opencode-nix.packages.x86_64-linux.default;
  };
}
```

## Version Pinning and Update Channels

Choose between immutable pins and moving update channels using git refs.

Only exact version tags such as `v1.14.46` or exact commit SHAs are true pins. `v1`, `latest`, and the default branch are moving refs that intentionally follow newer commits over time.

### Available Refs

| Ref | Example | Behavior | Security Posture |
| --- | --- | --- | --- |
| Exact version tag | `v1.14.46` | Immutable release tag | Best default for reproducible installs |
| Major tag | `v1` | Latest release in that major line | Moving channel, updates over time |
| `latest` tag | `latest` | Newest packaged release | Moving channel, updates over time |
| Default branch | `github:kubajanusz/opencode-nix` | Tracks repository `main` | Moving channel, fastest updates |

### Usage Examples

```bash
# Always latest from the default branch
nix run github:kubajanusz/opencode-nix

# Pin to an exact immutable release
nix run github:kubajanusz/opencode-nix?ref=v1.14.46

# Track latest v1.x
nix run github:kubajanusz/opencode-nix?ref=v1

# Track the moving latest tag
nix run github:kubajanusz/opencode-nix?ref=latest
```

### In Flake Inputs

```nix
{
  inputs = {
    # Always latest from the default branch
    opencode-nix.url = "github:kubajanusz/opencode-nix";

    # Pin to an exact immutable release
    opencode-nix.url = "github:kubajanusz/opencode-nix?ref=v1.14.46";

    # Track major version
    opencode-nix.url = "github:kubajanusz/opencode-nix?ref=v1";
  };
}
```

If you use this repository as a flake input, your own `flake.lock` records the resolved commit. Exact tags and commit SHAs give the strongest control; moving refs such as `main`, `v1`, and `latest` only change when you update your lock file.

## Security / Trust Model

This repository is optimized for fast stable OpenCode updates. That makes the trust model worth stating explicitly.

### What is verified today

- `package.nix` fetches native release archives with fixed hashes.
- `sources.json` records the expected version and per-platform hashes.
- `flake.lock` pins flake inputs for a given repository revision.
- CI builds and smoke-tests the package before update PRs land on `main`.
- The updater prefetches assets from the matching upstream GitHub release with Nix.

### What still requires trust

- Trusting this repo means trusting the maintainer account and the GitHub Actions workflow that creates update PRs.
- The upstream artifacts come from the `anomalyco/opencode` release page.
- Moving refs such as `main`, `v1`, and `latest` trade stricter change control for convenience and freshness.

### Recommended setups

| Goal | Recommended Setup |
| --- | --- |
| Highest assurance | Pin an exact commit SHA and review updates manually |
| Balanced default | Pin an exact version tag |
| Fastest updates | Track the default branch, `v1`, or `latest` |

### Forking

Forking is a valid option if you want to fully control update cadence, review upstream diffs yourself, or add additional policy checks before merging updates.

For most users, pinning an exact version tag is simpler and usually enough. A fork only meaningfully improves security if you also add your own review gate instead of automatically tracking upstream.

### Prefer Broader Review Over Speed?

If you prefer a slower update cadence with broader community review, upstream `nixpkgs` may be a better fit than this flake.

## Technical Details

### Package Architecture

- Downloads pre-built native binaries from OpenCode GitHub releases.
- Uses the stable CLI release assets:
  - `opencode-linux-x64.tar.gz`
  - `opencode-linux-arm64.tar.gz`
  - `opencode-darwin-x64.zip`
  - `opencode-darwin-arm64.zip`
- Uses `autoPatchelfHook` on Linux for NixOS compatibility.
- Installs the `opencode` binary into `$out/bin/opencode`.
- Keeps release version and hashes in `sources.json`.

### Supported Systems

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Development

```bash
# Clone the repository
git clone https://github.com/kubajanusz/opencode-nix
cd opencode-nix

# Enter development shell
nix develop

# Build the package
nix build

# Run a smoke test
./result/bin/opencode --version

# Check for version updates
./scripts/update-version.sh --check
```

## Updating OpenCode Version

### Automated Updates

This repository uses GitHub Actions to check for new OpenCode versions every hour. When a new version is detected:

1. A pull request is automatically created with the version update.
2. `sources.json` is updated with the new version and hashes for all supported platforms.
3. `flake.lock` is updated.
4. CI runs on Ubuntu and macOS.
5. Version tags are created only for newly packaged releases (`vX.Y.Z`, `vX`, `latest`).

The automated update workflow runs:

- every hour
- on manual trigger via the GitHub Actions UI

This workflow is designed for freshness and build validation, not for manual review of every upstream release.

Automated update PRs require repository settings that allow GitHub Actions to write contents and create pull requests. See `.github/REPOSITORY_SETTINGS.md` or run:

```bash
./scripts/setup-github-permissions.sh
```

### Manual Updates

#### Using the Update Script

```bash
# Check for updates
./scripts/update-version.sh --check

# Update to latest version
./scripts/update-version.sh

# Update to a specific version
./scripts/update-version.sh --version 1.14.46

# Print latest upstream version
./scripts/update-version.sh --latest-version

# Show help
./scripts/update-version.sh --help
```

The script automatically:

- fetches the latest upstream release version
- prefetches supported release assets with Nix
- updates `sources.json`
- updates `flake.lock`
- verifies that the package builds

#### Manual Process

If you prefer to update manually:

1. Edit `sources.json` and change the `version` field.
2. Prefetch each relevant release asset with `nix store prefetch-file --hash-type sha256 --json URL`.
3. Update the matching hash entries in `sources.json`.
4. Run `nix flake update`.
5. Build and test locally: `nix build && ./result/bin/opencode --version`.
6. Submit a pull request.

## Troubleshooting

### `opencode` asks to update

OpenCode may report that a newer version is available. With this flake, updates should happen through Nix:

```bash
nix profile upgrade '.*opencode.*'
```

or by updating your flake lock:

```bash
nix flake update opencode-nix
```

### `opencode` command not found

Check whether the Nix profile path is available:

```bash
echo "$PATH" | tr ':' '\n' | grep nix-profile
```

If you installed through NixOS or Home Manager, rebuild or switch your configuration and open a new shell.

## Alternatives

### Official Native Install

```bash
curl -fsSL https://opencode.ai/install | bash
```

### Package Managers

```bash
npm i -g opencode-ai@latest
brew install anomalyco/tap/opencode
nix run nixpkgs#opencode
nix run github:anomalyco/opencode
```

### Trade-offs

| Aspect | Official native install | This Nix flake |
| --- | --- | --- |
| Simplicity | One command | Requires Nix |
| Official binary | Yes | Yes |
| Stable releases | Yes | Yes |
| Latest stable version | Usually latest | Hourly checks |
| Version pinning | Manual | Git tags / commit SHAs |
| Rollback | Manual | Nix profile/system rollback |
| Declarative | No | NixOS/Home Manager |
| Windows | Native installer available | Use via WSL or unsupported directly |

Choose the official installer if you want the simplest setup or do not use Nix.

Choose this flake if you use NixOS or Home Manager, want declarative configuration, and are comfortable choosing between exact pins and faster-moving update channels.

## License

The Nix packaging in this repository is MIT licensed. OpenCode itself is MIT licensed by the OpenCode project.
