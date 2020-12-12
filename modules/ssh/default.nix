{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.ssh;

in {
  options = with lib; {
    my.ssh = {
      enable = mkEnableOption ''
        Whether to enable ssh module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      home-manager = {
        users.${username} = {
          home = {
            file = { ".ssh/config" = { source = ../../config/.ssh/config; }; };
          };
        };
      };
    };
}
