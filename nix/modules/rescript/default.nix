{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.rescript;

in {
  options = with lib; {
    my.rescript = {
      enable = mkEnableOption ''
        Whether to enable rescript module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ reason ]; };
    };
}
