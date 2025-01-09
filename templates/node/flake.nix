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
            volta
            nodePackages.pnpm
          ];
          shellHook = ''
            export VOLTA_HOME="$HOME/.volta"

            # These are for direnv
            export NODE_VERSIONS="$VOLTA_HOME/tools/image/node/"
            export NODE_VERSION_PREFIX=""

            export __DIRENV_NODE_VERSION__

            if [ -f "./.nvmrc" ]; then
               __DIRENV_NODE_VERSION__="$(<./.nvmrc)"
            elif [ -f "./.node-version" ]; then
               __DIRENV_NODE_VERSION__="$(<./.node-version)"
            fi

            # We only install it, direnv will load it
            if [ -x "$VOLTA_HOME/bin/volta" ]; then
            	volta install node@"$__DIRENV_NODE_VERSION__"
            fi
          '';
        };
      }
    );
}
