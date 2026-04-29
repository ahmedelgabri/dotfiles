_: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    utils = pkgs.writeShellApplication {
      name = "utils";
      text = builtins.readFile ../../../scripts/utils;
    };

    flakeRoot = ../../../.;
    bootstrapScript = ../../../scripts/${system}_bootstrap;
  in {
    apps =
      (
        if builtins.pathExists bootstrapScript
        then {
          default = {
            type = "app";
            program = pkgs.lib.getExe (pkgs.writeShellApplication {
              name = "bootstrap";
              runtimeInputs = [pkgs.git];
              text = ''
                export BOOTSTRAP_FLAKE_ROOT=${flakeRoot}

                # shellcheck disable=SC1091
                source ${pkgs.lib.getExe utils}
                ${builtins.readFile bootstrapScript}
              '';
            });
          };
        }
        else {}
      )
      // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
        sb = {
          type = "app";
          program = pkgs.lib.getExe pkgs.sb;
        };
      };

    packages =
      {
        inherit (pkgs) next-prayer;
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
        inherit (pkgs) sb;
      };
  };
}
