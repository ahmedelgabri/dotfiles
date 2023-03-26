{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.lf;

in
{
  options = with lib; {
    my.modules.lf = {
      enable = mkEnableOption ''
        Whether to enable lf module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.user = { packages = with pkgs; [ lf zoxide fzf ]; };

      my.hm.file = {
        ".config/lf" = {
          recursive = true;
          source = ../../../config/lf;
        };
      };
    };
}
