{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.go;

in
{
  options = with lib; {
    my.modules.go = {
      enable = mkEnableOption ''
        Whether to enable go module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.env = rec {
        GOPATH = "$XDG_DATA_HOME/go";
        GOBIN = "${GOPATH}/bin";
      };

      my.user = { packages = with pkgs; [ go ]; };
    };
}
