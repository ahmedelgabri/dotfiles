{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.misc;

in {
  options = with lib; {
    my.misc = {
      enable = mkEnableOption ''
        Whether to enable misc module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".gemrc" = { source = ./.gemrc; };
              ".curlrc" = { source = ./.curlrc; };
              ".ignore" = { source = ./.ignore; };
              ".mailcap" = { source = ./.mailcap; };
              ".psqlrc" = { source = ./.psqlrc; };
              ".urlview" = { source = ./.urlview; };
            };
          };
        };
      };
    };
}
