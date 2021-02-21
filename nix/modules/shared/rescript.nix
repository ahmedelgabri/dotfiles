{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.modules.rescript;

in {
  options = with lib; {
    my.modules.rescript = {
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
