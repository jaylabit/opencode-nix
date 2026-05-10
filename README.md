# opencode-nix

Nix package for the latest stable [OpenCode](https://github.com/anomalyco/opencode) CLI release from GitHub Releases.

This flake packages OpenCode's official native release archives instead of using `github:anomalyco/opencode`, which follows the upstream development branch.

**Automatically updated hourly** to keep this flake close to the latest stable OpenCode release.

## Quick start

```bash
nix run github:kubajanusz/opencode-nix
```

Install it into your profile:

```bash
nix profile install github:kubajanusz/opencode-nix
opencode --version
```

## Flake usage

Use the overlay:

```nix
{
  inputs.opencode-nix.url = "github:kubajanusz/opencode-nix";

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

Or reference the package directly:

```nix
opencode-nix.packages.x86_64-linux.default
```

## Supported systems

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Updating

The packaged version and fixed-output hashes live in `sources.json`.

```bash
# Check whether a newer release exists
./scripts/update-version.sh --check

# Update to the latest stable GitHub release
./scripts/update-version.sh

# Update to a specific version
./scripts/update-version.sh --version 1.14.46
```

The update script fetches release asset hashes with Nix, updates `sources.json`, updates `flake.lock`, and verifies the package build.

### Automated updates

This repository includes GitHub Actions workflows adapted from the reference packaging repository:

- `Build` runs flake checks, builds the package, and smoke-tests `opencode --version` on Ubuntu and macOS.
- `Update OpenCode Version` checks hourly for a newer stable GitHub release and opens an update PR only when the packaged version changes.
- `Create Version Tag` creates exact version tags like `v1.14.46` and moves `v1` and `latest` only for newly packaged releases.
- Dependabot checks GitHub Actions versions weekly.

Automated update PRs require GitHub Actions write permissions and auto-merge settings. See `.github/REPOSITORY_SETTINGS.md` or run:

```bash
./scripts/setup-github-permissions.sh
```

## Version pinning

Exact version tags such as `v1.14.46` are immutable release pins. The `v1`, `latest`, and default-branch refs are moving channels that update when this repository packages a newer OpenCode release.

## Development

```bash
nix develop
nix build
./result/bin/opencode --version
./scripts/update-version.sh --check
```

## License

The Nix packaging in this repository is MIT licensed. OpenCode itself is MIT licensed by the OpenCode project.
