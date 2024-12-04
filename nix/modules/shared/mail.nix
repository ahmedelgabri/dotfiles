{ pkgs, lib, config, ... }:

with config.my;

let

  cfg = config.my.modules.mail;
  homeDir = config.my.user.home;
  inherit (config.home-manager.users."${username}") xdg;
  inherit (pkgs.stdenv) isDarwin isLinux;

in
{
  options = with lib; {
    my.modules = {
      mail = {
        # TODO: support multiple accounts
        enable = mkEnableOption ''
          Whether to enable mail module
        '';
        account = mkOption {
          default = "Personal";
          type = with types; uniq str;
        };
        alias_path = mkOption {
          default = "${homeDir}/Sync/dotfiles/aliases";
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
    mkIf cfg.enable (mkMerge [
      (mkIf isDarwin {
        launchd.user.agents."isync" = {
          # This will call notmuch `pre-new` hook that will fetch new mail & addresses too
          # Check `.mail/.notmuch/hooks/`
          command =
            "${pkgs.notmuch}/bin/notmuch --config=${xdg.configHome}/notmuch/config new";
          serviceConfig = {
            ProcessType = "Background";
            LowPriorityIO = true;
            StartInterval = 2 * 60;
            RunAtLoad = true;
            KeepAlive = false;
            StandardOutPath = "${homeDir}/Library/Logs/isync-output.log";
            StandardErrorPath = "${homeDir}/Library/Logs/isync-error.log";
            EnvironmentVariables = {
              "SSL_CERT_FILE" = "/etc/ssl/certs/ca-certificates.crt";
            };
          };
        };
      })

      (mkIf isLinux {
        # systemd
      })

      {
        my.user = {
          packages = with pkgs; [
            neomutt
            msmtp
            isync
            w3m
            notmuch
            urlscan
            pass
          ];
        };

        my.env = {
          MAILDIR =
            "$HOME/.mail"; # will be picked up by .notmuch-config for database.path
          NOTMUCH_CONFIG = "$XDG_CONFIG_HOME/notmuch/config";
          # MAILCAP="$XDG_CONFIG_HOME/mailcap"; # elinks, w3m
          # MAILCAPS="$MAILCAP";   # Mutt, pine
        };

        system.activationScripts.postUserActivation.text = ''
          echo ":: -> Running mail activationScript..."

          if [ ! -e "${homeDir}/.mail/${cfg.account}" ]; then
            echo "Creating mail folder for account ${cfg.account} at ${homeDir}/.mail/${cfg.account}..."
            mkdir -p ${homeDir}/.mail/${cfg.account}
          fi
        '';

        my.hm.file = {
          ".config/neomutt" = {
            recursive = true;
            source = ../../../config/neomutt;
          };

          ".config/neomutt/accounts/${lib.toLower cfg.account}" = {
            text = ''
              # ${nix_managed}
              # vi:syntax=muttrc

              set realname = "${name}"
              set signature = ""
              # can't use pkgs.msmtp because it breaks in neomutt
              set sendmail = "msmtp -a ${lib.toLower cfg.account}"
              ${lib.optionalString (cfg.alias_path != "") ''
                set alias_file = "${cfg.alias_path}"
                source ${cfg.alias_path}''}
              set from = "${email}"
              set spoolfile = "+${cfg.account}/INBOX"
              ${if cfg.keychain.name == "fastmail.com" then
              ''set record =  "+${cfg.account}/Sent"''
              else
              ''unset record # don't save messages, gmail already does this.''}
              set postponed = "+${cfg.account}/Drafts"
              set mbox = "+${cfg.account}/Archive"
              set trash = "+${cfg.account}/Trash"
              set header_cache = "${xdg.cacheHome}/neomutt/headers/${cfg.account}/"
              set message_cachedir = "${xdg.cacheHome}/neomutt/messages/${cfg.account}/"
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
                `${pkgs.tree}/bin/tree ~/.mail/${cfg.account} -l -d -I "Archive|cur|new|tmp|certs|.notmuch|INBOX|[Gmail]" -afinQ --noreport | awk '{if(NR>1)print}' | tr '\n' ' '`

              ${lib.optionalString
              (lib.toLower cfg.account == "personal" && cfg.switch_to != "") ''
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
              # https://github.com/neomutt/neomutt/issues/4349#issuecomment-2268713737
              macro index,pager Y ":set resolve=no<enter><tag-thread>:set resolve=yes<enter><tag-prefix><save-message>=${cfg.account}/Archive<enter>" "Archive conversation"

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

              # TODO: support multiple accounts
              # {% for account in mail_accounts %}
              folder-hook +${cfg.account}/ source ${xdg.configHome}/neomutt/accounts/${
                lib.toLower cfg.account
              }
              # {% endfor %}

              # Source this file initially, so it acts like a default account
              source ${xdg.configHome}/neomutt/accounts/${
                lib.toLower cfg.account
              }'';
          };

          ".mail/.notmuch/hooks/pre-new" = {
            executable = true;
            text = ''
              #!/usr/bin/env sh
              # ${nix_managed}

              ${pkgs.coreutils}/bin/timeout 2m ${pkgs.isync}/bin/mbsync -q -a'';
          };

          ".config/notmuch/config" = {
            text = ''
              # ${nix_managed}
              #  vim:ft=conf

              # .notmuch-config - Configuration file for the notmuch mail system
              #
              # For more information about notmuch, see https://notmuchmail.org

              # Database configuration
              #
              # The only value supported here is 'path' which should be the top-level
              # directory where your mail currently exists and to where mail will be
              # delivered in the future. Files should be individual email messages.
              # Notmuch will store its database within a sub-directory of the path
              # configured here named ".notmuch".
              #

              # This section is set by setting up $MAILDIR
              [database]
              path=${homeDir}/.mail

              # User configuration
              #
              # Here is where you can let notmuch know how you would like to be
              # addressed. Valid settings are
              #
              #  name    Your full name.
              #  primary_email  Your primary email address.
              #  other_email  A list (separated by ';') of other email addresses
              #      at which you receive email.
              #
              # Notmuch will use the various email addresses configured here when
              # formatting replies. It will avoid including your own addresses in the
              # recipient list of replies, and will set the From address based on the
              # address to which the original email was addressed.
              #

              # This section is set by setting up $NAME & $EMAIL
              [user]
              name=${name}
              primary_email=${email}

              # Configuration for "notmuch new"
              #
              # The following options are supported here:
              #
              #  tags  A list (separated by ';') of the tags that will be
              #    added to all messages incorporated by "notmuch new".
              #
              #  ignore  A list (separated by ';') of file and directory names
              #    that will not be searched for messages by "notmuch new".
              #
              #    NOTE: *Every* file/directory that goes by one of those
              #    names will be ignored, independent of its depth/location
              #    in the mail store.
              #

              [new]
              tags=unread;inbox;
              ignore=.mbsyncstate;.DS_Store;.mbsyncstate.journal;.mbsyncstate.new;.mbsyncstate.lock;.uidvalidity

              # Search configuration
              #
              # The following option is supported here:
              #
              #  exclude_tags
              #    A ;-separated list of tags that will be excluded from
              #    search results by default.  Using an excluded tag in a
              #    query will override that exclusion.
              #

              [search]
              # exclude_tags=deleted;killed;spam;
              exclude_tags=deleted;spam;

              # Maildir compatibility configuration
              #
              # The following option is supported here:
              #
              #  synchronize_flags      Valid values are true and false.
              #
              #  If true, then the following maildir flags (in message filenames)
              #  will be synchronized with the corresponding notmuch tags:
              #
              #    Flag  Tag
              #    ----  -------
              #    D  draft
              #    F  flagged
              #    P  passed
              #    R  replied
              #    S  unread (added when 'S' flag is not present)
              #
              #  The "notmuch new" command will notice flag changes in filenames
              #  and update tags, while the "notmuch tag" and "notmuch restore"
              #  commands will notice tag changes and update flags in filenames
              #

              [maildir]
              synchronize_flags=true

              # Cryptography related configuration
              #
              # The following option is supported here:
              #
              #  gpg_path
              #    binary name or full path to invoke gpg.
              #

              [crypto]
              gpg_path=${pkgs.gnupg}/bin/gpg '';
          };

          # TODO: support multiple accounts
          ".config/msmtp/config" = {
            text = ''
              # ${nix_managed}

              defaults
              protocol smtp
              auth on
              tls on
              tls_trust_file /etc/ssl/certs/ca-certificates.crt
              logfile ~/Library/Logs/msmtp.log

              account ${lib.toLower cfg.account}
              ${lib.optionalString (cfg.keychain.name == "fastmail.com")
              "tls_starttls on"}
              ${lib.optionalString (cfg.keychain.name == "fastmail.com")
              "port 587"}
              host ${cfg.smtp_server}
              from ${email}
              user ${email}
              passwordeval ${xdg.configHome}/zsh/bin/get-keychain-pass ${cfg.keychain.account} ${cfg.keychain.name}
              # passwordeval ${pkgs.pass}/bin/pass email/${cfg.keychain.name}

              account default : ${lib.toLower cfg.account}'';
          };

          ".config/isyncrc" = {
            text = ''
              # ${nix_managed}
              # Settings for isync, a program to synchronise IMAP mailboxes
              # This file defines the synchronisation for two accounts, Personal and Work
              # The remote for each account is a server somewhere, and the local is a folder
              # in ~/.mail
              # Synchronise everything with `mbsync -a`

              ########################################
              # Default settings
              # Applied to all channels
              ########################################
              Create Near
              Expunge Both
              CopyArrivalDate yes
              SyncState *
              # TODO: support multiple accounts
              # {% for account in mail_accounts %}
              # {% if account.imap_user != "" %}
              ########################################
              # ${cfg.account}
              ########################################
              IMAPAccount ${cfg.account}
              PipelineDepth 100
              Host ${cfg.imap_server}
              User ${email}
              # Get the account password from the system Keychain
              # PassCmd "${pkgs.pass}/bin/pass email/${cfg.keychain.name}"
              PassCmd "~/.config/zsh/bin/get-keychain-pass '${cfg.keychain.account}' '${cfg.keychain.name}'"
              AuthMechs LOGIN
              TLSType IMAPS
              TLSVersions +1.2

              # Remote storage (where the mail is retrieved from)
              IMAPStore ${cfg.account}-remote
              Account ${cfg.account}

              # Local storage (where the mail is retrieved to)
              MaildirStore ${cfg.account}-local
              Path ~/.mail/${cfg.account}/ # The trailing "/" is important
              Inbox ~/.mail/${cfg.account}/INBOX
              SubFolders Verbatim

              Channel ${cfg.account}-inbox
              Far :${cfg.account}-remote:INBOX
              Near :${cfg.account}-local:INBOX

              Channel ${cfg.account}-archive
              ${if cfg.keychain.name == "fastmail.com" then
                "Far :${cfg.account}-remote:Archive"
              else
                ''Far :${cfg.account}-remote:"[Gmail]/All Mail"''}
              Near :${cfg.account}-local:Archive

              Channel ${cfg.account}-drafts
              ${if cfg.keychain.name == "fastmail.com" then
                "Far :${cfg.account}-remote:Drafts"
              else
                ''Far :${cfg.account}-remote:"[Gmail]/Drafts"''}
              Near :${cfg.account}-local:Drafts

              ${lib.optionalString (cfg.keychain.name == "gmail.com") ''
                Channel ${cfg.account}-starred
                Far :${cfg.account}-remote:"[Gmail]/Starred"
                Near :${cfg.account}-local:Starred''}

              Channel ${cfg.account}-sent
              ${if cfg.keychain.name == "fastmail.com" then
                "Far :${cfg.account}-remote:Sent"
              else
                ''Far :${cfg.account}-remote:"[Gmail]/Sent Mail"''}
              Near :${cfg.account}-local:Sent

              Channel ${cfg.account}-spam
              ${if cfg.keychain.name == "fastmail.com" then
                "Far :${cfg.account}-remote:Spam"
              else
                ''Far :${cfg.account}-remote:"[Gmail]/Spam"''}
              Near :${cfg.account}-local:Spam

              Channel ${cfg.account}-trash
              ${if cfg.keychain.name == "fastmail.com" then
                "Far :${cfg.account}-remote:Trash"
              else
                ''Far :${cfg.account}-remote:"[Gmail]/Trash"''}
              Near :${cfg.account}-local:Trash

              Channel ${cfg.account}-folders
              Far :${cfg.account}-remote:
              Near :${cfg.account}-local:
              # All folders except those defined above
              Patterns * !INBOX !Archive !Drafts ${
                lib.optionalString (cfg.keychain.name == "gmail.com")
                "!Starred "
              }!Sent !Spam !Trash ![Gmail]*

              # Group the channels, so that all channels can be sync'd with `mbsync ${
                lib.toLower cfg.account
              }`
              Group ${lib.toLower cfg.account}
              Channel ${cfg.account}-inbox
              Channel ${cfg.account}-archive
              Channel ${cfg.account}-drafts
              ${lib.optionalString (cfg.keychain.name == "gmail.com") ''Channel ${cfg.account}-starred''}
              Channel ${cfg.account}-sent
              Channel ${cfg.account}-spam
              Channel ${cfg.account}-trash
              Channel ${cfg.account}-folders

              # For doing a quick sync of just the INBOX with `mbsync ${
                lib.toLower cfg.account
              }-download`.
              Channel ${lib.toLower cfg.account}-download
              Far :${cfg.account}-remote:INBOX
              Near :${cfg.account}-local:INBOX
              Create Near
              Expunge Near
              Sync Pull'';
          };
        };
      }
    ]);
}
