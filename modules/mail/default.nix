{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.mail;

in {
  options = with lib; {
    my = {
      mail = { # [todo] support multiple accounts
        enable = mkEnableOption ''
          Whether to enable mail module
        '';
        account = mkOption {
          default = "Personal";
          type = with types; uniq str;
        };
        alias_path = mkOption {
          default = "${builtins.getEnv "HOME"}/Sync/dotfiles/aliases";
          type = with types; uniq str;
        };
        keychain = {
          name = mkOption {
            default = "fastmail.com";
            type = with types; uniq str;
          };
          account = mkOption {
            default = replaceStrings [ "@" ] [ "+mutt@" ] email;
            type = with types; uniq str;
          };
        };
        imap_server = mkOption {
          default = "imap.fastmail.com";
          type = with types; uniq str;
        };
        smtp_server = mkOption {
          default = "smtp.fastmail.com";
          type = with types; uniq str;
        };
        accent = mkOption {
          default = "color238";
          type = with types; uniq str;
        };
        switch_to = mkOption {
          default = "";
          type = with types; uniq str;
        };
      };

    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = {
        packages = with pkgs; [ lbdb neomutt msmtp isync ];
      };

      environment.userLaunchAgents."com.ahmedelgabri.isync.plist" = {
        text = ''
          <!-- ${nix_managed} -->
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple/DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
            <dict>
              <key>Label</key>
              <string>com.ahmedelgabri.isync</string>
              <key>ProgramArguments</key>
              <array>
                <string>/bin/sh</string>
                <string>-c</string>
                <string>exec ${
                  builtins.getEnv "HOME"
                }/.config/neomutt/scripts/mail-sync</string>
              </array>
              <key>RunAtLoad</key>
              <true/>
              <key>KeepAlive</key>
              <true/>
              <key>StartInterval</key>
              <integer>120</integer>
              <key>StandardOutPath</key>
              <string>/tmp/ahmed.isync.log</string>
              <key>StandardErrorPath</key>
              <string>/tmp/ahmed.isync.err.log</string>
            </dict>
          </plist>'';
      };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/neomutt/neomuttrc" = {
                text = ''
                  # ${nix_managed}
                  source ./muttrc'';
              };
              ".config/neomutt/muttrc" = {
                text = ''
                  # ${nix_managed}
                  ${builtins.readFile ./muttrc}'';
              };
              ".config/neomutt/accounts/${lib.toLower cfg.account}" = {
                text = ''
                  # ${nix_managed}
                  # vi:syntax=muttrc

                  set realname = "${name}"
                  set sendmail = "${pkgs.msmtp} -a ${lib.toLower cfg.account}"
                  ${lib.optionalString (cfg.alias_path != "") ''
                    set alias_file = "${cfg.alias_path}"
                    source ${cfg.alias_path}''}
                  set from = "${email}"
                  set spoolfile = "+${cfg.account}/INBOX"
                  set postponed = "+${cfg.account}/Drafts"
                  set mbox = "+${cfg.account}/Archive"
                  set trash = "+${cfg.account}/Trash"
                  set header_cache = "${
                    builtins.getEnv "HOME"
                  }/.cache/neomutt/headers/${cfg.account}/"
                  set message_cachedir = "${
                    builtins.getEnv "HOME"
                  }/.cache/neomutt/messages/${cfg.account}/"
                  unmailboxes *
                  mailboxes "+${cfg.account}/INBOX" ${
                    if cfg.keychain.name == "gmail.com" then
                      ''"+${cfg.account}/Starred" \''
                    else
                      "\\"
                  }
                    "+${cfg.account}/Sent" \
                    "+${cfg.account}/Drafts" \
                    "+${cfg.account}/Trash" \
                    "+${cfg.account}/Spam" \
                    `tree ~/.mail/${cfg.account} -l -d -I "Archive|cur|new|tmp|certs|.notmuch|INBOX|[Gmail]" -afin --noreport | awk '{if(NR>1)print}' | tr '\n' ' '`

                  ${lib.optionalString
                  (lib.toLower cfg.account == "personal" && cfg.switch_to != "")
                  ''
                    macro index,pager gw "<change-folder>=${cfg.switch_to}/INBOX<enter>" "Switch account to ${cfg.switch_to}"''}

                  ${lib.optionalString (cfg.keychain.name == "gmail.com") ''
                    macro index,pager gs "<change-folder>=${cfg.account}/Starred<enter>" "go to Starred"
                    macro browser gs "<exit><change-folder>=${cfg.account}/Starred<enter>" "go to Starred"''}

                  macro index,pager gt "<change-folder>=${cfg.account}/Sent<enter>" "go to Sent"
                  macro browser gt "<exit><change-folder>=${cfg.account}/Sent<enter>" "go to Sent"
                  macro index,pager gd "<change-folder>=${cfg.account}/Drafts<enter>" "go to Drafts"
                  macro browser gd "<exit><change-folder>=${cfg.account}/Drafts<enter>" "go to Drafts"

                  macro index,pager / "<vfolder-from-query>path:${cfg.account}/** " "Searching ${cfg.account} mailbox with notmuch integration in neomutt"

                  macro index SI "<shell-escape>mbsync --pull ${
                    lib.toLower cfg.account
                  }<enter>" "sync inbox"
                  macro index,pager y "<save-message>=${cfg.account}/Archive<enter>" "Archive conversation"
                  macro index,pager Y "<tag-thread><save-message>=${cfg.account}/Archive<enter>" "Archive conversation"

                  color status ${cfg.accent} default
                  color sidebar_highlight black ${cfg.accent}
                  color sidebar_indicator ${cfg.accent} color0
                  color indicator black ${cfg.accent} # currently selected message
                    '';
              };

              ".config/neomutt/config/hooks.mutt" = {
                text = ''
                  # ${nix_managed}
                  # vi:syntax=muttrc

                  # [todo] support multiple accounts
                  # {% for account in mail_accounts %}
                  # folder-hook +${cfg.account}/ source "${
                    builtins.getEnv "HOME"
                  }/.config/neomutt/account/${lib.toLower cfg.account}/"
                  # {% endfor %}

                  # Source this file initially, so it acts like a default account
                  source ${cfg.account}/ source "${
                    builtins.getEnv "HOME"
                  }/.config/neomutt/account/${lib.toLower cfg.account}/"
                                '';

              };

              ".config/neomutt/config/bindings.mutt" = {
                text = ''
                  # ${nix_managed}
                  ${builtins.readFile ./bindings.mutt}'';
                # macro pager \Cu "<enter-command>set pipe_decode = yes<enter>|${pkgs.urlview}/bin/urlview<enter><enter-command>set pipe_decode = no<enter>" "view URLs"'';
              };

              ".config/neomutt/config/colors.mutt" = {
                text = ''
                  # ${nix_managed}
                  ${builtins.readFile ./colors.mutt}'';
              };

              ".config/neomutt/scripts/mail-sync" = {
                executable = true;
                text = ''
                  #!/usr/bin/env sh
                  # ${nix_managed}

                  # This will call notmuch `pre-new` hook that will fetch new mail & addresses too
                  # Check `.mail/.notmuch/hooks/`
                  ${pkgs.notmuch}/bin/notmuch --config=/Users/${username}/.config/notmuch/config new'';
              };

              ".config/neomutt/scripts/dump-ical.py" = {
                executable = true;
                source = ./dump-ical.py;
              };

              ".config/neomutt/scripts/view-mail.sh" = {
                executable = true;
                source = ./view-mail.sh;
              };

              ".config/neomutt/scripts/view-attachment.sh" = {
                executable = true;
                source = ./view-attachment.sh;
              };

              ".mail/.notmuch/hooks/pre-new" = {
                executable = true;
                text = ''
                  #!/usr/bin/env sh
                  # ${nix_managed}

                  ${pkgs.coreutils}/bin/timeout 2m ${pkgs.isync}/bin/mbsync -q -a

                  find  /Users/${username}/.mail/*/INBOX -type f -mtime -30d -print -exec sh -c 'cat {} | ${pkgs.lbdb}/bin/lbdb-fetchaddr' \; 2>/dev/null'';
              };
            };
          };
        };
      };
    };
}
