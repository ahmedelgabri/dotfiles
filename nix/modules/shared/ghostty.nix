{ lib, config, ... }:

let

  cfg = config.my.modules.ghostty;

in
{
  options = with lib; {
    my.modules.ghostty = {
      enable = mkEnableOption ''
        Whether to enable ghostty module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
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
