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
        ...
      }: {
        # This sets `pkgs` to a nixpkgs with allowUnfree option set.
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        formatter = let
          treefmtEval = treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs = {
              alejandra.enable = true;
              ruff-format.enable = true;
              ruff-check.enable = true;
            };
          };
        in
          treefmtEval.config.build.wrapper;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            uv
            treefmt
          ];
          shellHook =
            /*
            bash
            */
            ''
              if [ ! -f pyproject.toml ]; then
                ${pkgs.lib.getExe pkgs.uv} init --author-from git

                # in order to make sure pyright LSP plays well
                echo '[tool.pyright]\nvenvPath = "."\nvenv = ".venv"' >> pyproject.toml

                ${pkgs.lib.getExe pkgs.uv} tool install ruff
                ${pkgs.lib.getExe pkgs.uv} tool install pyright
              fi

              # Activate Python virtual environment
              if [ ! -d .venv ]; then
                ${pkgs.lib.getExe pkgs.uv} venv
              fi
              source .venv/bin/activate

              # Install project dependencies
              ${pkgs.lib.getExe pkgs.uv} sync

              echo "Development environment ready!"
            '';
        };
      };
    };
}
