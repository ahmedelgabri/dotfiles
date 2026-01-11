# Apps module
# Bootstrap scripts for different systems
{...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    utils = pkgs.writeShellApplication {
      name = "utils";
      text = builtins.readFile ../../scripts/utils;
    };
    bootstrap = pkgs.writeShellApplication {
      name = "bootstrap";
      runtimeInputs = [pkgs.git];
      text = ''
        # shellcheck disable=SC1091
        source ${pkgs.lib.getExe utils}
        ${builtins.readFile ../../scripts/${system}_bootstrap}
      '';
    };
  in {
    apps = {
      default = {
        type = "app";
        program = pkgs.lib.getExe bootstrap;
      };
    };
  };
}
