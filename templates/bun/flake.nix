{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    treefmt-nix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      perSystem = {
        pkgs,
        system,
        self',
        ...
      }: let
        treefmtCfg = {
          projectRootFile = "flake.nix";
          settings = {
            # Do not exit with error if a configured formatter is missing
            allow-missing-formatter = true;

            # Log paths that did not match any formatters at the specified log level
            # Possible values are <debug|info|warn|error|fatal>
            on-unmatched = "info";

            # The method used to traverse the files within the tree root
            # Currently, we support 'auto', 'git', 'jujutsu', or 'filesystem'
            walk = "git";

            global.excludes = [
              "*.gitignore"
              "*.ignore"
              "*.lock"
              ".next"
              "LICENSE"
              "build"
              "dist"
              "node_modules"
            ];
          };
          programs = {
            alejandra.enable = true;
            prettier.enable = true;
          };
        };
      in {
        # This sets `pkgs` to a nixpkgs with allowUnfree option set.
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        formatter = let
          treefmtEval = treefmt-nix.lib.evalModule pkgs treefmtCfg;
        in
          treefmtEval.config.build.wrapper;

        checks = let
          treefmtEval =
            treefmt-nix.lib.evalModule
            pkgs
            treefmtCfg;
        in {
          formatting = treefmtEval.config.build.check self';
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bun
          ];

          shellHook = ''
            bun -e 'console.log(`You are running Bun v${"$"}{Bun.version}`)'
          '';
        };
      };
    };
}
