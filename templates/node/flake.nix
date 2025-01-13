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

        # Grab node version from .nvmrc file if exits otherwise fallback to latest node
        # version schema depends on volta version schema
        getNodeVersion = list: let
          result =
            builtins.filter (v: v != "")
            (builtins.map (
                p:
                  if builtins.pathExists p
                  then nixpkgs.lib.trim (builtins.readFile p)
                  else ""
              )
              list);
        in
          if builtins.length result > 0
          then "node@${builtins.head result}"
          else "node";

        # This is a list of paths not strings, order matters because it will
        # return the first version it finds
        nodeVersion = getNodeVersion [./.nvmrc ./.node-version];
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

            # direnv wants only the version number, empty string will let it get the latest
            export __DIRENV_NODE_VERSION__="${
              if nodeVersion == "node"
              then ""
              else nodeVersion
            }"

            # We only install it, direnv will load it
            if [ -x "$VOLTA_HOME/bin/volta" ]; then
            	volta install "${nodeVersion}"
            fi
          '';
        };
      }
    );
}
