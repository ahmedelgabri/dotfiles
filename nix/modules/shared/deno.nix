{ pkgs, lib, config, inputs, ... }:

let

  cfg = config.my.modules.deno;

in
{
  options = with lib; {
    my.modules.deno = {
      enable = mkEnableOption ''
        Whether to enable deno module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my = {
        user = {
          packages = with pkgs; [
            deno
          ];
        };
      };
    };
}
