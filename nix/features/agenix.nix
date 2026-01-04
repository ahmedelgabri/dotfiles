{inputs, ...}: let
  # The actual NixOS module for agenix configuration
  agenixModule = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.agenix;
  in {
    options = with lib; {
      my.modules.agenix = {
        enable = mkEnableOption ''
          Whether to enable agenix module
        '';
      };
    };

    config = with lib;
      mkIf cfg.enable {
        environment = {
          shellAliases = {
            agenix = "agenix -i ~/.ssh/agenix";
          };
        };
      };
  };
in {
  # Define modules for both darwin and nixos to import
  flake.modules.darwin.agenix = agenixModule;
  flake.modules.nixos.agenix = agenixModule;
}
