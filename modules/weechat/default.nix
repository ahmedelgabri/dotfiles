{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.weechat;
  xdg = config.home-manager.users.${username}.xdg;

in {
  options = with lib; {
    my.weechat = {
      enable = mkEnableOption ''
        Whether to enable weechat module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.variables = {
        WEECHAT_HOME = "${xdg.configHome}/weechat";
        WEECHAT_PASSPHRASE = ''
          `security find-generic-password -g -a weechat 2>&1| perl -e 'if (<STDIN> =~ m/password: \"(.*)\"$/ ) { print $1; }'`'';
      };

      users.users.${username} = { packages = with pkgs; [ weechat ]; };
    };
}
