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
                ${pkgs.lib.getExe pkgs.uv} init --author-from git

                # in order to make sure pyright LSP plays well
                echo "[tool.basedpyright]\nvenvPath = \".\"\nvenv = \".venv\"" >> pyproject.toml

                ${pkgs.lib.getExe pkgs.uv} add --dev ruff
                ${pkgs.lib.getExe pkgs.uv} add --dev basedpyright
                ${pkgs.lib.getExe pkgs.uv} add --dev ty
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
