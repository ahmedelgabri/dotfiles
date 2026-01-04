{inputs, ...}: let
  # The actual NixOS module for discord configuration
  discordModule = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.discord;
    inherit (pkgs.stdenv) isDarwin isLinux;
  in {
    options = with lib; {
      my.modules.discord = {
        enable = mkEnableOption ''
          Whether to enable discord module
        '';
      };
    };

    config = with lib;
      mkIf cfg.enable (mkMerge [
        (mkIf isDarwin {
          homebrew.casks = ["discord"];
        })
        (mkIf isLinux {
          my.user = {packages = with pkgs; [discord];};
        })
      ]);
  };
in {
  # Define modules for both darwin and nixos to import
  flake.modules.darwin.discord = discordModule;
  flake.modules.nixos.discord = discordModule;
}
