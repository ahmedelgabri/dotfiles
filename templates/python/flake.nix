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
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            uv
          ];
          shellHook =
            /*
            bash
            */
            ''
              if [ ! -f ./pyproject.toml ]; then
                uv init --author-from git

                # in order to make sure pyright LSP plays well
                cat <<EOF >> pyproject.toml

                [tool.pyright]
                venvPath = "."
                venv = ".venv"
                EOF

                uv tool install ruff
                uv tool install pyright
              fi
            '';
        };
      }
    );
}
