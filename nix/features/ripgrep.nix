{inputs, ...}: let
  # The actual NixOS module for ripgrep configuration
  ripgrepModule = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.ripgrep;
  in {
    options = with lib; {
      my.modules.ripgrep = {
        enable = mkEnableOption ''
          Whether to enable ripgrep module
        '';
      };
    };

    config = with lib;
      mkIf cfg.enable {
        my.env = {RIPGREP_CONFIG_PATH = "$XDG_CONFIG_HOME/ripgrep/config";};

        my.user = {packages = with pkgs; [ripgrep];};

        my.hm.file = {
          ".config/ripgrep" = {
            recursive = true;
            source = ../../config/ripgrep;
          };
        };
      };
  };
in {
  # Define modules for both darwin and nixos to import
  flake.modules.darwin.ripgrep = ripgrepModule;
  flake.modules.nixos.ripgrep = ripgrepModule;
}
