{ pkgs, lib, config, ... }:

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
    mkIf cfg.enable { my.user = { packages = with pkgs; [ reason ]; }; };
}
