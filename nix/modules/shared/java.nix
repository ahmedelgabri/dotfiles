{ pkgs, lib, config, ... }:

with config.my;

let

  cfg = config.my.modules.java;
  xdg = config.home-manager.users.${username}.xdg;

in {
  options = with lib; {
    my.modules.java = {
      enable = mkEnableOption ''
        Whether to enable java module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.variables = {
        "_JAVA_OPTIONS" =
          ''-Djava.util.prefs.userRoot="${xdg.configHome}/java"'';
      };

      users.users.${username} = {
        packages = with pkgs; [
          go-jira
          vagrant
          maven # How to get 3.5? does it matter?
          jdk8 # is this the right package?
        ];
      };
    };
}
