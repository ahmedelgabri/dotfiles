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
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            uv
            python3
            ruff
            pyright
          ];
          shellHook = ''
            if [ ! -f ./pyproject.toml ]; then
              # in order to make sure pyright LSP plays well
              uv init && echo '\n[tool.pyright]\nvenvPath = "."\nvenv = ".venv"' >> pyproject.toml
            fi
          '';
        };
      }
    );
}
