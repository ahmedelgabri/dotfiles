{
  pkgs,
  lib,
  config,
  ...
}:
with config.my; let
  cfg = config.my.modules.mail;
  homeDir = config.my.user.home;
  inherit (config.home-manager.users."${username}") xdg;
in {
  options = with lib; {
    my.modules = {
      mail = {
        # TODO: support multiple accounts
        enable = mkEnableOption ''
          Whether to enable mail module
        '';

        account = {
          type = mkOption {
            default = "Personal";
            type = with types; uniq str;
          };

          name = mkOption {
            default = "Personal";
            type = with types; uniq str;
          };

          service = mkOption {
            default = "fastmail.com";
            type = with types; uniq str;
          };
        };

        source_server = mkOption {
          default = "jmap+oauthbearer://${config.my.email}@api.fastmail.com/.well-known/jmap";
          type = with types; uniq str;
        };

        source_cred_cmd = mkOption {
          default = "${lib.getExe pkgs.pass} show service/email/source";
          type = with types; uniq str;
        };

        outgoing_server = mkOption {
          default = "jmap://";
          type = with types; uniq str;
        };

        outgoing_cred_cmd = mkOption {
          default = "${lib.getExe pkgs.pass} show service/email/outgoing";
          type = with types; uniq str;
        };

        carddav_source_cred_cmd = mkOption {
          default = "${lib.getExe pkgs.pass} show service/email/contacts";
          type = with types; uniq str;
        };

        # These are needed for mbysnc and local syncing
        password_cmd = mkOption {
          default = "${lib.getExe pkgs.pass} show service/email/password";
          type = with types; uniq str;
        };

        imap_server = mkOption {
          default = "imap.fastmail.com";
          type = with types; uniq str;
        };

        smtp_server = mkOption {
          default = "smtp.fastmail.com";
          type = with types; uniq str;
        };
      };
    };
  };

  config = with lib;
    mkIf cfg.enable (
      mkMerge [
        (mkIf pkgs.stdenv.isDarwin {
          launchd.user.agents."mailsync" = {
            # `pass` needs to have proper gpg setup
            environment = {
              GNUPGHOME = "${xdg.configHome}/gnupg";
              SSH_AUTH_SOCK = "${xdg.configHome}/gnupg/S.gpg-agent.ssh";
            };
            command =
              pkgs.writeShellScript "mailsync"
              /*
              bash
              */
              ''
                set -ue -o pipefail

                # `pass` needs gpg agent running so it can retrieve passwords from the store
                ${lib.getExe' pkgs.gnupg "gpg-connect-agent"}

                echo "--- Starting mail sync at $(date) ---"
                ${lib.getExe' pkgs.coreutils "timeout"} ${
                  if cfg.account.service == "gmail.com"
                  then "5m"
                  else "2m"
                } ${lib.getExe pkgs.isync} -q -a

                echo "mbsync finished successfully. Indexing new mail..."
                ${lib.getExe pkgs.notmuch} --config=${xdg.configHome}/notmuch/config new

                echo "Sync finished at $(date)"'';

            serviceConfig = {
              ProcessType = "Background";
              LowPriorityIO = true;
              StartInterval = 2 * 60;
              RunAtLoad = true;
              KeepAlive = false;
              StandardOutPath = "${homeDir}/Library/Logs/mailsync-output.log";
              StandardErrorPath = "${homeDir}/Library/Logs/mailsync-error.log";
              EnvironmentVariables = {
                "SSL_CERT_FILE" = "/etc/ssl/certs/ca-certificates.crt";
              };
            };
          };
        })

        (mkIf pkgs.stdenv.isLinux {
          # systemd
        })

        (mkIf (cfg.account.service == "gmail.com") {
          my.hm.file = {
            ".config/aerc/folder-map" = {
              text = ''
                Archive=[Gmail]/All Mail
                Sent=[Gmail]/Sent Mail
                Drafts=[Gmail]/Drafts
                Spam=[Gmail]/Spam
                Starred=[Gmail]/Starred
                Trash=[Gmail]/Trash
              '';
            };
          };
        })

        {
          system.activationScripts.postActivation.text = ''
            echo ":: -> Running mail activationScript..."

            if [ ! -e "${homeDir}/.mail/${cfg.account.type}" ]; then
              echo "Creating mail folder for account ${cfg.account.type} at ${homeDir}/.mail/${cfg.account.type}..."
              mkdir -p ${homeDir}/.mail/${cfg.account.type}
            fi
          '';

          my = {
            user = {
              packages = with pkgs; [
                aerc
                isync
                pass
                msmtp
                isync
                w3m
                notmuch
                urlscan
              ];
            };

            env = {
              MAILDIR = "$HOME/.mail"; # will be picked up by .notmuch-config for database.path
              NOTMUCH_CONFIG = "$XDG_CONFIG_HOME/notmuch/config";
            };

            hm.file = {
              ".config/aerc/stylesets" = {
                recursive = true;
                source = ../../../config/aerc/stylesets;
              };

              ".config/aerc/binds.conf" = {source = ../../../config/aerc/binds.conf;};
              ".config/aerc/querymap" = {source = ../../../config/aerc/querymap;};
              ".config/aerc/aerc.conf" = {source = ../../../config/aerc/aerc.conf;};

              ".config/aerc/accounts.conf" = {
                ###############################################################################
                # Maybe I should always connect remotely and ignore the local sync all together?
                # - will be slower in taking actions or opening folders (network requests)
                # - requires `folder-map` to handle `[Gmail]/*` prefix
                # - should I get rid of service for account type? personal/work, etc...?
                ###############################################################################

                text = ''
                  [${cfg.account.name}]
                  from              = ${config.my.name} <${config.my.email}>
                  source            = maildir://~/.mail/${cfg.account.type}
                  # source            = ${cfg.source_server}
                  # source-cred-cmd   = ${cfg.source_cred_cmd}
                  # outgoing          = ${cfg.outgoing_server}
                  outgoing = msmtp -a ${lib.toLower cfg.account.type}
                  copy-to           = Sent
                  postpone          = Drafts
                  archive           = Archive
                  default           = INBOX
                  folders-sort      = INBOX, Starred, Drafts, Sent, Trash, Archive, Spam
                  # signature-file    = ~/.signature.local
                  ${lib.optionalString (cfg.account.service == "gmail.com") ''
                    folder-map  = ~/.config/aerc/folder-map
                    cache-headers = true''}

                  ${lib.optionalString (cfg.account.service == "fastmail.com") ''
                    # https://lists.sr.ht/~rjarry/aerc-discuss/%3CD8FESFHT3XQ3.O21TH7KHQBOU@fastmail.com%3E#%3CD8FV5SWTKJNG.8IHCST9O3ZVR@fastmail.com%3E
                    use-labels        = true
                    cache-state       = true
                    cache-blobs       = true
                    use-envelope-from = true
                    carddav-source = https://${config.my.email}@carddav.fastmail.com/dav/addressbooks/user/${config.my.email}/Default
                    carddav-source-cred-cmd = ${cfg.carddav_source_cred_cmd}
                    address-book-cmd = carddav-query -S ${cfg.account.type} %s''}

                  # [notmuch]
                  # source            = notmuch://~/.mail/
                  # query-map         = ~/.config/aerc/querymap'';
              };

              # This is the exact same as in `mail.nix`
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
                  name=${config.my.name}
                  primary_email=${config.my.email}

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
                  exclude_tags=deleted;spam;trash;

                  [query]
                  inbox=tag:inbox and tag:unread
                  sent=tag:sent
                  archive=not tag:inbox
                  github=tag:github or from:notifications@github.com
                  urgent=tag:urgent

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
                  gpg_path=${lib.getExe pkgs.gnupg} '';
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

                  account ${lib.toLower cfg.account.type}
                  ${lib.optionalString (cfg.account.service == "fastmail.com")
                    "tls_starttls on"}
                  port 587
                  host ${cfg.smtp_server}
                  from ${config.my.email}
                  user ${config.my.email}
                  passwordeval ${cfg.password_cmd}

                  account default : ${lib.toLower cfg.account.type}'';
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
                  Create Both
                  Expunge Both
                  CopyArrivalDate yes

                  # Sync mailboxes both ways
                  Sync All

                  # - Remove: If a folder is deleted on the server, also delete it locally.
                  Remove Near

                  SyncState *
                  # TODO: support multiple accounts
                  # {% for account in mail_accounts %}
                  # {% if account.imap_user != "" %}
                  ########################################
                  # ${cfg.account.name}
                  ########################################
                  IMAPAccount ${cfg.account.type}
                  PipelineDepth 100
                  Host ${cfg.imap_server}
                  User ${config.my.email}
                  # Get the account password from the system Keychain
                  PassCmd "${cfg.password_cmd}"
                  AuthMechs LOGIN
                  TLSType IMAPS
                  TLSVersions +1.2
                  ${lib.optionalString (cfg.account.service == "gmail.com") ''PipelineDepth 1''}

                  # Remote storage (where the mail is retrieved from)
                  IMAPStore ${cfg.account.type}-remote
                  Account ${cfg.account.type}

                  # Local storage (where the mail is retrieved to)
                  MaildirStore ${cfg.account.type}-local
                  Path ~/.mail/${cfg.account.type}/ # The trailing "/" is important
                  Inbox ~/.mail/${cfg.account.type}/INBOX
                  SubFolders Verbatim

                  Channel ${cfg.account.type}-inbox
                  Far :${cfg.account.type}-remote:INBOX
                  Near :${cfg.account.type}-local:INBOX


                  ${lib.optionalString (cfg.account.service == "fastmail.com") ''
                    Channel ${cfg.account.type}-archive
                    Far :${cfg.account.type}-remote:Archive
                    Near :${cfg.account.type}-local:Archive''}


                  Channel ${cfg.account.type}-drafts
                  ${
                    if cfg.account.service == "fastmail.com"
                    then "Far :${cfg.account.type}-remote:Drafts"
                    else ''Far :${cfg.account.type}-remote:"[Gmail]/Drafts"''
                  }
                  Near :${cfg.account.type}-local:Drafts

                  ${lib.optionalString (cfg.account.service == "gmail.com") ''
                    Channel ${cfg.account.type}-starred
                    Far :${cfg.account.type}-remote:"[Gmail]/Starred"
                    Near :${cfg.account.type}-local:Starred''}

                  Channel ${cfg.account.type}-sent
                  ${
                    if cfg.account.service == "fastmail.com"
                    then "Far :${cfg.account.type}-remote:Sent"
                    else ''Far :${cfg.account.type}-remote:"[Gmail]/Sent Mail"''
                  }
                  Near :${cfg.account.type}-local:Sent

                  Channel ${cfg.account.type}-spam
                  ${
                    if cfg.account.service == "fastmail.com"
                    then "Far :${cfg.account.type}-remote:Spam"
                    else ''Far :${cfg.account.type}-remote:"[Gmail]/Spam"''
                  }
                  Near :${cfg.account.type}-local:Spam

                  Channel ${cfg.account.type}-trash
                  ${
                    if cfg.account.service == "fastmail.com"
                    then "Far :${cfg.account.type}-remote:Trash"
                    else ''Far :${cfg.account.type}-remote:"[Gmail]/Trash"''
                  }
                  Near :${cfg.account.type}-local:Trash

                  Channel ${cfg.account.type}-folders
                  Far :${cfg.account.type}-remote:
                  Near :${cfg.account.type}-local:
                  # All folders except those defined above
                  Patterns * !INBOX !Archive !Drafts ${
                    lib.optionalString (cfg.account.service == "gmail.com")
                    ''!Starred !"Version Control" !"Version Control/*" !GitHub !GitHub/* !"Inbox - CC" "!Inbox - CC/*" ''
                  }!Sent !Spam !Trash ![Gmail]*

                  # Group the channels, so that all channels can be sync'd with `mbsync ${
                    lib.toLower cfg.account.type
                  }`
                  Group ${lib.toLower cfg.account.type}
                  Channel ${cfg.account.type}-inbox
                  Channel ${cfg.account.type}-archive
                  Channel ${cfg.account.type}-drafts
                  Channel ${cfg.account.type}-sent
                  Channel ${cfg.account.type}-spam
                  Channel ${cfg.account.type}-trash
                  Channel ${cfg.account.type}-folders
                  ${lib.optionalString (cfg.account.service == "gmail.com") ''Channel ${cfg.account.type}-starred''}

                  # For doing a quick sync of just the INBOX with `mbsync ${
                    lib.toLower cfg.account.type
                  }-download`.
                  Channel ${lib.toLower cfg.account.type}-download
                  Far :${cfg.account.type}-remote:INBOX
                  Near :${cfg.account.type}-local:INBOX
                  Create Near
                  Expunge Near
                  Sync Pull'';
              };
            };
          };
        }
      ]
    );
}
