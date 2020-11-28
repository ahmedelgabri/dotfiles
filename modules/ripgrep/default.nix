{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.ripgrep;

in {
  options = with lib; {
    my.ripgrep = {
      enable = mkEnableOption ''
        Whether to enable ripgrep module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ ripgrep ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = { ".config/ripgrep/config" = { source = ./config; }; };
          };
        };
      };
    };
}
