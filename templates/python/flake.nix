{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
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
        formatter = pkgs.alejandra;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            uv
          ];
          shellHook =
            /*
            bash
            */
            ''
              if [ ! -f pyproject.toml ]; then
                ${pkgs.uv}/bin/uv init --author-from git

                # in order to make sure pyright LSP plays well
                echo '[tool.pyright]\nvenvPath = "."\nvenv = ".venv"' >> pyproject.toml

                ${pkgs.uv}/bin/uv tool install ruff
                ${pkgs.uv}/bin/uv tool install pyright
              fi

              # Activate Python virtual environment
              if [ ! -d .venv ]; then
                ${pkgs.uv}/bin/uv venv
              fi
              source .venv/bin/activate

              # Install project dependencies
              ${pkgs.uv}/bin/uv sync

              echo "Development environment ready!"
            '';
        };
      };
    };
}
