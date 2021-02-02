# [todo] https://github.com/balsoft/nixos-config/blob/64e3aeb311f1e0c5c2ccaef94f04d51a72e48b48/modules/applications/weechat.nix
{ pkgs, lib, config, inputs, ... }:

with config.settings;

let

  cfg = config.my.irc;
  xdg = config.home-manager.users.${username}.xdg;

in {
  options = with lib; {
    my.irc = {
      enable = mkEnableOption ''
        Whether to enable irc module
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

      nixpkgs = {
        overlays = [
          (final: prev: {
            # https://github.com/NixOS/nixpkgs/issues/106506#issuecomment-742639055
            weechat = prev.weechat.override {
              configure = { availablePlugins, ... }: {
                plugins = with availablePlugins;
                  [ (perl.withPackages (p: [ p.PodParser ])) ] ++ [ python ];
                scripts = with prev.weechatScripts;
                  [ wee-slack weechat-autosort colorize_nicks ]
                  ++ final.lib.optionals (!final.stdenv.isDarwin)
                  [ weechat-notify-send ];
              };
            };
          })
        ];
      };

      users.users.${username} = { packages = with pkgs; [ weechat ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              # [todo] WeeChat will need to modify these files, how can this be done?
              ".config/weechat" = {
                recursive = true;
                source = ../../../config/weechat;
              };

              ".config/weechat/perl/autoload/atcomplete.pl".source =
                "${inputs.weechat-scripts}/perl/atcomplete.pl";

              ".config/weechat/perl/autoload/highmon.pl".source =
                "${inputs.weechat-scripts}/perl/highmon.pl";

              ".config/weechat/perl/autoload/iset.pl".source =
                "${inputs.weechat-scripts}/perl/iset.pl";

              ".config/weechat/perl/autoload/multiline.pl".source =
                "${inputs.weechat-scripts}/perl/multiline.pl";

              ".config/weechat/python/autoload/autojoin.py".source =
                "${inputs.weechat-scripts}/python/autojoin.py";

              ".config/weechat/python/autoload/bitlbee_completion.py".source =
                "${inputs.weechat-scripts}/python/bitlbee_completion.py";

              ".config/weechat/python/autoload/go.py".source =
                "${inputs.weechat-scripts}/python/go.py";

              ".config/weechat/python/autoload/screen_away.py".source =
                "${inputs.weechat-scripts}/python/screen_away.py";

              # [Note] DARWIN ONLY
              ".config/weechat/python/autoload/notification_center.py".source =
                "${inputs.weechat-scripts}/python/notification_center.py";

              ".config/weechat/lua/autoload/emoji.lua".source =
                "${inputs.weechat-scripts}/lua/emoji.lua";
            };
          };
        };
      };
    };
}
