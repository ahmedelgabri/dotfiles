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

      flakeRoot = ../../../.;
      bootstrapScript = ../../../scripts/${system}_bootstrap;

      # tart comes from Homebrew (not in nixpkgs), so it is taken from PATH.
      test-bootstrap = pkgs.writeShellApplication {
        name = "test-bootstrap";
        runtimeInputs = with pkgs; [
          coreutils
          gnutar
          openssh
          sshpass
        ];
        text = ''
          export TEST_BOOTSTRAP_SOURCE=${flakeRoot}

          ${builtins.readFile ../../../scripts/test-bootstrap}
        '';
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
        inherit (pkgs) next-prayer agent-history;
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        inherit (pkgs) sb;
        inherit test-bootstrap;
      };
    };
}
