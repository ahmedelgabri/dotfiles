{ pkgs, lib, config, inputs, ... }:

let

  cfg = config.my.modules.hledger;

in
{
  options = with lib; {
    my.modules.hledger = {
      enable = mkEnableOption ''
        Whether to enable hledger module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my = {
        user = {
          packages = with pkgs; [
            hledger
            hledger-web
            hledger-ui
          ];
        };
      };
    };
}
