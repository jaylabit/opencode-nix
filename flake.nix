{
  description = "Nix package for OpenCode stable release builds";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      overlay = final: prev: {
        opencode = final.callPackage ./package.nix { };
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          default = pkgs.opencode;
          opencode = pkgs.opencode;
        };

        apps = {
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
        };

        formatter = pkgs.nixfmt;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            curl
            gh
            jq
            nixfmt
          ];
        };
      }
    )
    // {
      overlays.default = overlay;
    };
}
