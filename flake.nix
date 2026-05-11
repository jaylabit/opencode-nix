{
  description = "Nix package for OpenCode stable release builds";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      overlay = final: prev: {
        opencode = final.callPackage ./package.nix { };
      };

      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f (
            import nixpkgs {
              inherit system;
              overlays = [ overlay ];
            }
          )
        );
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.opencode;
        opencode = pkgs.opencode;
      });

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${pkgs.opencode}/bin/opencode";
          meta.description = "Run OpenCode";
        };
        opencode = {
          type = "app";
          program = "${pkgs.opencode}/bin/opencode";
          meta.description = "Run OpenCode";
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            curl
            gh
            jq
            nixfmt
          ];
        };
      });

      overlays.default = overlay;
    };
}
