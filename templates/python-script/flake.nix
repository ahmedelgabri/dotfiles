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
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      imports = [inputs.treefmt-nix.flakeModule];
      perSystem = {
        pkgs,
        system,
        ...
      }: {
        # This sets `pkgs` to a nixpkgs with allowUnfree option set.
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        treefmt = {
          projectRootFile = "flake.nix";
          settings = {
            # Log paths that did not match any formatters at the specified log level
            # Possible values are <debug|info|warn|error|fatal>
            on-unmatched = "info";

            global.excludes = [
              "*.gitignore"
              "*.ignore"
              "*.lock"
              "LICENSE"
              ".venv/*"
              "venv/*"
              "__pycache__/*"
              "*.egg-info"
            ];
          };

          programs = {
            alejandra.enable = true;
            statix.enable = true;
            ruff-format.enable = true;
            ruff-check = {
              enable = true;
              priority = 1;
            };
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            uv
          ];
          shellHook =
            /*
            bash
            */
            ''uv init --script main.py'';
        };
      };
    };
}
