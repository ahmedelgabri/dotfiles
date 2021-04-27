{ pkgs, lib, config, options, ... }:

let

  cfg = config.my.modules.discord;

in
{
  options = with lib; {
    my.modules.discord = {
      enable = mkEnableOption ''
        Whether to enable discord module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (if (builtins.hasAttr "homebrew" options) then {
        homebrew.casks = [ "discord" ];
      } else {
        my.user = { packages = with pkgs; [ discord ]; };
      })
    ]);
}
