{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.modules.ghostty;
  inherit (pkgs.stdenv) isDarwin isLinux;
in {
  options = with lib; {
    my.modules.ghostty = {
      enable = mkEnableOption ''
        Whether to enable ghostty module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (mkIf isDarwin {
        homebrew.casks = [
          "ghostty@tip"
        ];
      })
      (mkIf isLinux {
        my.user = {
          packages = with pkgs; [
            # Broken on Darwin that's why we have two branches
            ghostty
          ];
        };
      })
      {
        my = {
          # user = {
          #   packages = with pkgs; [
          #     ghostty
          #   ];
          # };
          hm.file = {
            ".config/ghostty" = {
              recursive = true;
              source = ../../../config/ghostty;
            };
          };
        };
      }
    ]);
}
