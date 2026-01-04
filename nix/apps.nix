# Bootstrap and utility apps - perSystem outputs
{...}: {
  perSystem = {pkgs, system, ...}: {
    # Formatter for nix files
    formatter = pkgs.alejandra;

    # Bootstrap apps
    apps = let
      utils = pkgs.writeShellApplication {
        name = "utils";
        text = builtins.readFile ../scripts/utils;
      };
      bootstrap = pkgs.writeShellApplication {
        name = "bootstrap";
        runtimeInputs = [pkgs.git];
        text = ''
          # shellcheck disable=SC1091
          source ${pkgs.lib.getExe utils}
          ${builtins.readFile ../scripts/${system}_bootstrap}
        '';
      };
    in {
      default = {
        type = "app";
        program = pkgs.lib.getExe bootstrap;
      };
    };
  };
}
