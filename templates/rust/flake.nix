{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        formatter = pkgs.alejandra;
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              cargo
              rust-analyzer-unwrapped
              rustPackages.clippy
              rustc
              rustfmt
            ];

            RUST_SRC_PATH = rustPlatform.rustLibSrc;

            shellHook =
              /*
              bash
              */
              ''
              '';
          };
      }
    );
}
