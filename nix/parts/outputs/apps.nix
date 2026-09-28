_: {
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    let
      utils = pkgs.writeShellApplication {
        name = "utils";
        text = builtins.readFile ../../../scripts/utils;
      };

      doctor = pkgs.writeShellApplication {
        name = "doctor";
        runtimeInputs = [ pkgs.gnupg ];
        text = builtins.readFile ../../../scripts/doctor;
      };

      # Everything that checks the repo, locally and in CI. Flake checks have
      # no network or token, so zizmor's online audits (impostor commits,
      # known-vulnerable actions, ...) run here after them. `nix` comes from
      # the caller's PATH.
      lint = pkgs.writeShellApplication {
        name = "lint";
        runtimeInputs = [
          pkgs.gh
          pkgs.zizmor
        ];
        text = ''
          if [ ! -f flake.nix ]; then
            echo "Run from the root of the dotfiles checkout" >&2
            exit 1
          fi

          # Evaluating darwin hosts on a Linux runner only works without
          # import-from-derivation.
          nix flake check --all-systems --no-write-lock-file --option allow-import-from-derivation false

          # zizmor reads GH_TOKEN or GITHUB_TOKEN; ask gh only when neither is set.
          if [ -z "''${GH_TOKEN:-}''${GITHUB_TOKEN:-}" ]; then
            GH_TOKEN=$(gh auth token)
            export GH_TOKEN
          fi
          zizmor --no-progress .github
        '';
      };

      flakeRoot = ../../../.;
      bootstrapScript = ../../../scripts/${system}_bootstrap;

      # tart comes from Homebrew (not in nixpkgs), so it is taken from PATH.
      test-bootstrap = pkgs.writeShellApplication {
        name = "test-bootstrap";
        runtimeInputs = with pkgs; [
          coreutils
          openssh
          sshpass
        ];
        text = builtins.readFile ../../../scripts/test-bootstrap;
      };
    in
    {
      apps =
        (
          if builtins.pathExists bootstrapScript then
            {
              default = {
                type = "app";
                program = pkgs.lib.getExe (
                  pkgs.writeShellApplication {
                    name = "bootstrap";
                    runtimeInputs = [
                      pkgs.git
                      doctor
                    ];
                    text = ''
                      export BOOTSTRAP_FLAKE_ROOT=${flakeRoot}

                      # shellcheck disable=SC1091
                      source ${pkgs.lib.getExe utils}
                      ${builtins.readFile bootstrapScript}
                    '';
                  }
                );
                meta.description = "Bootstrap a dotfiles host configuration";
              };
            }
          else
            { }
        )
        // {
          lint = {
            type = "app";
            program = pkgs.lib.getExe lint;
            meta.description = "Run the flake checks and zizmor's online workflow audits";
          };
          doctor = {
            type = "app";
            program = pkgs.lib.getExe doctor;
            meta.description = "Check that this machine finished setup";
          };
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          sb = {
            type = "app";
            program = pkgs.lib.getExe pkgs.sb;
            meta.description = "Manage sandbox VMs for isolated development";
          };
          test-bootstrap = {
            type = "app";
            program = pkgs.lib.getExe test-bootstrap;
            meta.description = "Run bootstrap in a disposable Tart macOS VM";
          };
        };

      packages = {
        inherit doctor;
        inherit (pkgs) next-prayer zh;
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        inherit (pkgs) sb;
        inherit test-bootstrap;
      };
    };
}
