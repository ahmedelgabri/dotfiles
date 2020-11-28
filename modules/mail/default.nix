{ pkgs, lib, config, ... }:

with config.settings;

{
  users.users.${config.settings.username} = {
    packages = with pkgs; [ lbdb neomutt msmtp isync ];
  };

  environment.userLaunchAgents."com.ahmedelgabri.isync.plist".text = ''
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
          <string>exec /Users/${username}/.config/neomutt/scripts/mail-sync</string>
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
    </plist>
      '';

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
          ".config/neomutt/accounts/${lib.toLower mail.account}" = {
            text = ''
              # ${nix_managed}
              # vi:syntax=muttrc

              set realname = "${name}"
              set sendmail = "${pkgs.msmtp} -a ${lib.toLower mail.account}"
              ${lib.optionalString (mail.alias_path != "") ''
                set alias_file = "${mail.alias_path}"
                source ${mail.alias_path}''}
              set from = "${email}"
              set spoolfile = "+${mail.account}/INBOX"
              set postponed = "+${mail.account}/Drafts"
              set mbox = "+${mail.account}/Archive"
              set trash = "+${mail.account}/Trash"
              set header_cache = "${
                builtins.getEnv "HOME"
              }/.cache/neomutt/headers/${mail.account}/"
              set message_cachedir = "${
                builtins.getEnv "HOME"
              }/.cache/neomutt/messages/${mail.account}/"
              unmailboxes *
              mailboxes "+${mail.account}/INBOX" ${
                if mail.keychain.name == "gmail.com" then
                  ''"+${mail.account}/Starred" \''
                else
                  "\\"
              }
                "+${mail.account}/Sent" \
                "+${mail.account}/Drafts" \
                "+${mail.account}/Trash" \
                "+${mail.account}/Spam" \
                `tree ~/.mail/${mail.account} -l -d -I "Archive|cur|new|tmp|certs|.notmuch|INBOX|[Gmail]" -afin --noreport | awk '{if(NR>1)print}' | tr '\n' ' '`

              ${lib.optionalString
              (lib.toLower mail.account == "personal" && mail.switch_to != "")
              ''
                macro index,pager gw "<change-folder>=${mail.switch_to}/INBOX<enter>" "Switch account to ${mail.switch_to}"''}

              ${lib.optionalString (mail.keychain.name == "gmail.com") ''
                macro index,pager gs "<change-folder>=${mail.account}/Starred<enter>" "go to Starred"
                macro browser gs "<exit><change-folder>=${mail.account}/Starred<enter>" "go to Starred"''}

              macro index,pager gt "<change-folder>=${mail.account}/Sent<enter>" "go to Sent"
              macro browser gt "<exit><change-folder>=${mail.account}/Sent<enter>" "go to Sent"
              macro index,pager gd "<change-folder>=${mail.account}/Drafts<enter>" "go to Drafts"
              macro browser gd "<exit><change-folder>=${mail.account}/Drafts<enter>" "go to Drafts"

              macro index,pager / "<vfolder-from-query>path:${mail.account}/** " "Searching ${mail.account} mailbox with notmuch integration in neomutt"

              macro index SI "<shell-escape>mbsync --pull ${
                lib.toLower mail.account
              }<enter>" "sync inbox"
              macro index,pager y "<save-message>=${mail.account}/Archive<enter>" "Archive conversation"
              macro index,pager Y "<tag-thread><save-message>=${mail.account}/Archive<enter>" "Archive conversation"

              color status ${mail.accent} default
              color sidebar_highlight black ${mail.accent}
              color sidebar_indicator ${mail.accent} color0
              color indicator black ${mail.accent} # currently selected message
                '';
          };

          ".config/neomutt/config/hooks.mutt" = {
            text = ''
              # ${nix_managed}
              # vi:syntax=muttrc

              # [todo] support multiple accounts
              # {% for account in mail_accounts %}
              # folder-hook +${mail.account}/ source "${
                builtins.getEnv "HOME"
              }/.config/neomutt/account/${lib.toLower mail.account}/"
              # {% endfor %}

              # Source this file initially, so it acts like a default account
              source ${mail.account}/ source "${
                builtins.getEnv "HOME"
              }/.config/neomutt/account/${lib.toLower mail.account}/"
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
}
