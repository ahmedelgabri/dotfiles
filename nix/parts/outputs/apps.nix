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
        };

      packages = {
        inherit doctor;
        inherit (pkgs) next-prayer agent-history;
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        inherit (pkgs) sb;
      };
    };
}
