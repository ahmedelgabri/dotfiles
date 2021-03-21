{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.misc;

in
{
  options = with lib; {
    my.modules.misc = {
      enable = mkEnableOption ''
        Whether to enable misc module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.hm.file = {
        ".gemrc" = { source = ../../../config/.gemrc; };
        ".curlrc" = { source = ../../../config/.curlrc; };
        ".ignore" = { source = ../../../config/.ignore; };
        ".mailcap" = { source = ../../../config/.mailcap; };
        ".psqlrc" = { source = ../../../config/.psqlrc; };
        ".urlview" = { source = ../../../config/.urlview; };
      };
    };
}
