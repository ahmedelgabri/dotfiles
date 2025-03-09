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
            volta
            nodePackages.pnpm
          ];
          shellHook =
            /*
            bash
            */
            ''
              if [[ ! -d "$HOME/.volta" ]]; then
                mkdir -p "$HOME/.volta"
              fi

              export VOLTA_HOME="$HOME/.volta";
              export PATH="$VOLTA_HOME/bin:$PATH"
              export NODE_VERSIONS="$VOLTA_HOME/tools/image/node"
              export NODE_VERSION_PREFIX=""
              export __DIRENV_NODE_VERSION__=""

              if [ -f "./.nvmrc" ]; then
                 __DIRENV_NODE_VERSION__="$(<./.nvmrc)"
              elif [ -f "./.node-version" ]; then
                 __DIRENV_NODE_VERSION__="$(<./.node-version)"
              fi

              volta install node@"$__DIRENV_NODE_VERSION__"
            '';
        };
      }
    );
}
