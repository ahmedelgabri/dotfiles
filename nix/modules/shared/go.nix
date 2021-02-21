{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.modules.go;
  xdg = config.home-manager.users.${username}.xdg;
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

      users.users.${username} = { packages = with pkgs; [ go ]; };
    };
}
