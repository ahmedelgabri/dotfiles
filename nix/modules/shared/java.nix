{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.java;

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
      my.env = {
        "_JAVA_OPTIONS" =
          ''-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME/java"'';
      };

      my.user = {
        packages = with pkgs; [
          go-jira
          vagrant
          maven # How to get 3.5? does it matter?
          jdk8 # is this the right package?
        ];
      };
    };
}
