{ pkgs, lib, config, inputs, ... }:

let

  cfg = config.my.modules.ttrv;
  ttrv = pkgs.callPackage ../../pkgs/ttrv.nix { source = inputs.ttrv; };

in
{
  options = with lib; {
    my.modules.ttrv = {
      enable = mkEnableOption ''
        Whether to enable ttrv module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.user = { packages = with pkgs; [ ttrv ]; };

      my.hm.file = {
        ".config/ttrv" = {
          recursive = true;
          source = ../../../config/ttrv;
        };
      };
    };
}
