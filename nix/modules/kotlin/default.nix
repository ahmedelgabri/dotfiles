{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.kotlin;

in {
  options = with lib; {
    my.kotlin = {
      enable = mkEnableOption ''
        Whether to enable kotlin module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ kotlin ktlint ]; };
    };
}
