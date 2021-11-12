# TODO: https://github.com/balsoft/nixos-config/blob/64e3aeb311f1e0c5c2ccaef94f04d51a72e48b48/modules/applications/weechat.nix
{ pkgs, lib, config, inputs, ... }:

let

  cfg = config.my.modules.irc;
  inherit (config.my.user) home;

in
{
  options = with lib; {
    my.modules.irc = {
      enable = mkEnableOption ''
        Whether to enable irc module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my = {
        user = {
          packages = with pkgs; [
            (weechat.override
              {
                configure = { availablePlugins, ... }: {
                  plugins = with availablePlugins;
                    [
                      (perl.withPackages (p: [ p.PodParser ]))
                      (python.withPackages (ps: [
                        ps.websocket_client
                        # ps.pync # requires 2.x
                      ]))
                    ];
                  scripts = with pkgs.weechatScripts;
                    [ wee-slack weechat-autosort colorize_nicks ]
                    ++ lib.optionals (!pkgs.stdenv.isDarwin)
                      [ weechat-notify-send ];
                };
              })
          ];
        };
        env = {
          WEECHAT_HOME = "$XDG_CONFIG_HOME/weechat";
          WEECHAT_PASSPHRASE = ''
            `security find-generic-password -g -a weechat 2>&1| perl -e 'if (<STDIN> =~ m/password: \"(.*)\"$/ ) { print $1; }'`'';
        };

        hm.file = {
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

          # Note: DARWIN ONLY
          ".config/weechat/python/autoload/notification_center.py".source =
            "${inputs.weechat-scripts}/python/notification_center.py";

        };
      };

      system.activationScripts.postUserActivation.text = ''
        echo ":: -> Running weechat activationScript..."
        # Handle mutable configs

        if [ ! -e "${home}/.config/weechat/irc.conf" ]; then
          echo "Linking weechat/irc.conf..."
          ln -sf ${home}/.dotfiles/config/weechat/irc.conf ${home}/.config/weechat/irc.conf
        fi

        if [ ! -e "${home}/.config/weechat/plugins.conf" ]; then
          echo "Linking weechat/plugins.conf..."
          ln -sf ${home}/.dotfiles/config/weechat/plugins.conf ${home}/.config/weechat/plugins.conf
        fi

        if [ ! -e "${home}/.config/weechat/sec.conf" ]; then
          echo "Linking weechat/sec.conf..."
          ln -sf ${home}/.dotfiles/config/weechat/sec.conf ${home}/.config/weechat/sec.conf
        fi

        if [ ! -e "${home}/.config/weechat/weechat.conf" ]; then
          echo "Linking weechat/weechat.conf..."
          ln -sf ${home}/.dotfiles/config/weechat/weechat.conf ${home}/.config/weechat/weechat.conf
        fi

        if [ ! -e "${home}/.config/weechat/buflist.conf" ]; then
          echo "Linking weechat/buflist.conf..."
          ln -sf ${home}/.dotfiles/config/weechat/buflist.conf ${home}/.config/weechat/buflist.conf
        fi
      '';

    };
}
