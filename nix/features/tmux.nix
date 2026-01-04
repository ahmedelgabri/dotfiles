{inputs, ...}: let
  # The actual NixOS module for tmux configuration
  tmuxModule = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.tmux;
  in {
    options = with lib; {
      my.modules.tmux = {
        enable = mkEnableOption ''
          Whether to enable tmux module
        '';
      };
    };

    config = with lib;
      mkIf cfg.enable {
        environment = {
          shellAliases = {
            # https://github.com/direnv/direnv/wiki/Tmux
            tmux = "direnv exec / tmux";
          };
        };

        my.user = {
          packages = with pkgs; [
            tmux
            next-prayer
          ];
        };

        my.hm.file = {
          ".config/tmux" = {
            recursive = true;
            source = ../../config/tmux;
          };
        };
      };
  };
in {
  # Define modules for both darwin and nixos to import
  flake.modules.darwin.tmux = tmuxModule;
  flake.modules.nixos.tmux = tmuxModule;
}
