{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.go;
  xdg = config.home-manager.users.${config.my.username}.xdg;
  go_path = "${xdg.dataHome}/go";

in {
  options = with lib; {
    my.modules.go = {
      enable = mkEnableOption ''
        Whether to enable go module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.variables = {
        GOPATH = go_path;
        GOBIN = "${go_path}/bin";
      };

      my.user = { packages = with pkgs; [ go ]; };
    };
}
