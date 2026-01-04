{inputs, ...}: let
  mailModule = {
    pkgs,
    lib,
    config,
    ...
  }:
    with config.my; let
      cfg = config.my.modules.mail;
      homeDir = config.my.user.home;
      inherit (config.home-manager.users."${username}") xdg;

      # Helper functions for multi-account support
      primaryAccount = lib.head cfg.accounts;
      lowerName = account: lib.toLower account;

      # Service-specific defaults lookup
      serviceDefaults = {
        "fastmail.com" = {
          imap = {
            server = "imap.fastmail.com";
          };
          smtp = {
            server = "smtp.fastmail.com";
          };
          aerc = {
            source_server = email: "jmap+oauthbearer://${email}@api.fastmail.com/.well-known/jmap";
            outgoing_server = "jmap://";
          };
          carddav = {
            enabled = true;
            source = "https://${email}@carddav.fastmail.com/dav/addressbooks/user/${email}/Default";
          };
          map = {
            enabled = false;
          };
          mbsync = {
            folders = [
              {
                name = "INBOX";
                remote = "INBOX";
              }
              {
                name = "Drafts";
                remote = "Drafts";
              }
              {
                name = "Archive";
                remote = "Archive";
              }
              {
                name = "Spam";
                remote = "Spam";
              }
              {
                name = "Sent";
                remote = "Sent";
              }
              {
                name = "Trash";
                remote = "Trash";
              }
            ];
            extra_exclusion_patterns = "";
          };
        };
        "cirrux.me" = {
          imap = {
            server = "imap.cirrux.co";
          };
          smtp = {
            server = "smtp.cirrux.co";
          };
          aerc = {
            source_server = _: "";
            outgoing_server = "";
          };
          carddav = {
            enabled = false;
            source = "api.cirrux.co";
          };
          map = {
            enabled = false;
            text = ''
              Archive=ARCHIVE
              Sent=SENT
              Drafts=DRAFT
              Spam=JUNK
              Trash=TRASH
            '';
          };
          mbsync = {
            folders = [
              {
                name = "INBOX";
                remote = "INBOX";
              }
              {
                name = "Drafts";
                remote = "DRAFT";
              }
              {
                name = "Archive";
                remote = "ARCHIVE";
              }
              {
                name = "Spam";
                remote = "JUNK";
              }
              {
                name = "Notes";
                remote = "Notes";
              }
              {
                name = "Sent";
                remote = "SENT";
              }
              {
                name = "Trash";
                remote = "TRASH";
              }
            ];
            extra_exclusion_patterns = "";
          };
        };
        "gmail.com" = rec {
          imap = {
            server = "imap.gmail.com";
          };
          smtp = {
            server = "smtp.gmail.com";
          };
          aerc = {
            source_server = _: "imaps://gmail.com@${imap.server}";
            outgoing_server = "smtps+plain://gmail.com@${smtp.server}";
          };
          carddav = {
            enabled = false;
          };
          map = {
            enabled = true;
            text = ''
              Archive=[Gmail]/All Mail
              Sent=[Gmail]/Sent Mail
              Drafts=[Gmail]/Drafts
              Spam=[Gmail]/Spam
              Starred=[Gmail]/Starred
              Trash=[Gmail]/Trash
            '';
          };
          mbsync = {
            folders = [
              {
                name = "INBOX";
                remote = "INBOX";
              }
              {
                name = "Drafts";
                remote = ''"[Gmail]/Drafts"'';
              }
              {
                name = "Archive";
                remote = ''"[Gmail]/Archive"'';
              }
              {
                name = "Spam";
                remote = ''"[Gmail]/Spam"'';
              }
              {
                name = "Sent";
                remote = ''"[Gmail]/Sent Mail"'';
              }
              {
                name = "Trash";
                remote = ''"[Gmail]/Trash"'';
              }
              {
                name = "Starred";
                remote = ''"[Gmail]/Starred"'';
              }
            ];
            extra_exclusion_patterns = "![Gmail]*";
          };
        };
      };
    in {
      options = with lib; {
        my.modules = {
          mail = {
            enable = mkEnableOption ''
              Whether to enable mail module
            '';

            accounts = mkOption {
              type = types.listOf (types.submodule ({config, ...}: let
                svcDefaults = serviceDefaults.${config.service};
              in {
                options = {
                  name = mkOption {
                    default = "Personal";
                    type = types.str;
                    description = "Account name (e.g., 'Personal', 'Work')";
                  };

                  email = mkOption {
                    type = types.str;
                    default = email; # This will use the outer 'email' variable from config.my
                    description = "Email address for this account";
                  };

                  service = mkOption {
                    type = types.enum ["fastmail.com" "gmail.com" "cirrux.me"];
                    default = "fastmail.com";
                    description = "Email service provider";
                  };

                  imap = mkOption {
                    type = types.submodule {
                      options = {
                        server = mkOption {
                          type = types.str;
                          default = svcDefaults.imap.server;
                          description = "IMAP server hostname";
                        };
                        password_cmd = mkOption {
                          type = types.str;
                          default = "${lib.getExe pkgs.pass} show service/email/${lib.toLower config.name}/password";
                          description = "Command to retrieve IMAP password";
                        };
                      };
                    };
                    default = {};
                  };

                  smtp = mkOption {
                    type = types.submodule {
                      options = {
                        server = mkOption {
                          type = types.str;
                          default = svcDefaults.smtp.server;
                          description = "SMTP server hostname";
                        };
                        password_cmd = mkOption {
                          type = types.str;
                          default = "${lib.getExe pkgs.pass} show service/email/${lib.toLower config.name}/password";
                          description = "Command to retrieve SMTP password";
                        };
                      };
                    };
                    default = {};
                  };

                  aerc = mkOption {
                    type = types.nullOr (types.submodule {
                      options = {
                        source_server = mkOption {
                          type = types.str;
                          default = svcDefaults.aerc.source_server config.email;
                          description = "JMAP source server URL";
                        };
                        source_cred_cmd = mkOption {
                          type = types.str;
                          default = "${lib.getExe pkgs.pass} show service/email/${lib.toLower config.name}/source";
                          description = "Command to retrieve JMAP source credentials";
                        };
                        outgoing_server = mkOption {
                          type = types.str;
                          default = svcDefaults.aerc.outgoing_server;
                          description = "JMAP outgoing server URL";
                        };
                        outgoing_cred_cmd = mkOption {
                          type = types.str;
                          default = "${lib.getExe pkgs.pass} show service/email/${lib.toLower config.name}/outgoing";
                          description = "Command to retrieve JMAP outgoing credentials";
                        };
                      };
                    });
                    default = {};
                    description = "JMAP configuration (automatically enabled for supported services)";
                  };

                  carddav = mkOption {
                    type = types.nullOr (types.submodule {
                      options = {
                        cred_cmd = mkOption {
                          type = types.str;
                          default = "${lib.getExe pkgs.pass} show service/email/${lib.toLower config.name}/contacts";
                          description = "Command to retrieve CardDAV credentials";
                        };
                      };
                    });
                    default =
                      if svcDefaults.carddav.enabled
                      then {}
                      else null;
                    description = "CardDAV configuration (automatically enabled for supported services)";
                  };

                  map = mkOption {
                    type = types.submodule {
                      options = {
                        enabled = mkOption {
                          type = types.bool;
                          default = svcDefaults.map.enabled;
                          description = "Whether to enable folder mapping";
                        };
                        text = mkOption {
                          type = types.str;
                          default = svcDefaults.map.text;
                          description = "Folder mapping configuration content";
                        };
                      };
                    };
                    default = {};
                    description = "Folder mapping configuration for aerc";
                  };

                  mbsync = mkOption {
                    type = types.submodule {
                      options = {
                        folders = mkOption {
                          type = types.listOf (types.submodule {
                            options = {
                              name = mkOption {
                                type = types.str;
                                description = "Local folder name";
                              };
                              remote = mkOption {
                                type = types.str;
                                description = "Remote folder name";
                              };
                            };
                          });
                          default = svcDefaults.mbsync.folders;
                          description = "List of folders to sync";
                        };
                        extra_exclusion_patterns = mkOption {
                          type = types.str;
                          default = svcDefaults.mbsync.extra_exclusion_patterns;
                          description = "Additional exclusion patterns for the folders channel";
                        };
                      };
                    };
                    default = svcDefaults.mbsync;
                    description = "mbsync folder configuration";
                  };
                };
              }));
              default = [{}];
              description = "List of email accounts (first account is primary)";
            };
          };
        };
      };

      config = with lib;
        mkIf cfg.enable (
          mkMerge [
            (mkIf pkgs.stdenv.isDarwin {
              launchd.user.agents."mailsync" = let
                # Determine max timeout needed across all accounts
                maxTimeout = let
                  hasGmail = lib.any (acc: acc.service == "gmail.com") cfg.accounts;
                in
                  if hasGmail
                  then "5m"
                  else "2m";
              in {
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
                    ${lib.getExe' pkgs.coreutils "timeout"} ${maxTimeout} ${lib.getExe pkgs.isync} -q -a

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

            (mkIf (lib.any (acc: acc.map.enabled) cfg.accounts) {
              my.hm.file = lib.mkMerge (
                map (acc:
                  lib.mkIf acc.map.enabled {
                    ".config/aerc/${lowerName acc.name}-folder-map" = {
                      inherit (acc.map) text;
                    };
                  })
                cfg.accounts
              );
            })

            {
              system.activationScripts.postActivation.text = ''
                echo ":: -> Running mail activationScript..."

                ${lib.concatStringsSep "\n" (
                  map (account: ''
                    if [ ! -e "${homeDir}/.mail/${account.name}" ]; then
                      echo "Creating mail folder for account ${account.name} at ${homeDir}/.mail/${account.name}..."
                      mkdir -p ${homeDir}/.mail/${account.name}
                    fi
                  '')
                  cfg.accounts
                )}
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
                    source = ../../config/aerc/stylesets;
                  };

                  ".config/aerc/binds.conf" = {source = ../../config/aerc/binds.conf;};
                  ".config/aerc/querymap" = {source = ../../config/aerc/querymap;};
                  ".config/aerc/aerc.conf" = {source = ../../config/aerc/aerc.conf;};

                  ".config/aerc/accounts.conf" = {
                    ###############################################################################
                    # Maybe I should always connect remotely and ignore the local sync all together?
                    # - will be slower in taking actions or opening folders (network requests)
                    # - requires `folder-map` to handle `[Gmail]/*` prefix
                    # - should I get rid of service for account type? personal/work, etc...?
                    ###############################################################################

                    text = lib.concatStringsSep "\n" (
                      map (
                        account: ''
                          [${account.name}]
                          from              = ${config.my.name} <${account.email}>
                          source            = maildir://~/.mail/${account.name}
                          # source            = ${lib.optionalString (account.aerc.source_server != null) account.aerc.source_server}
                          # source-cred-cmd   = ${lib.optionalString (account.aerc.source_cred_cmd != null) account.aerc.source_cred_cmd}
                          # outgoing          = ${lib.optionalString (account.aerc.outgoing_server != null) account.aerc.outgoing_server}
                          outgoing = msmtp -a ${lowerName account.name}
                          copy-to           = Sent
                          postpone          = Drafts
                          archive           = Archive
                          default           = INBOX
                          folders-sort      = INBOX, Starred, Drafts, Sent, Trash, Archive, Spam
                          # signature-file    = ~/.signature.local
                          ${lib.optionalString account.map.enabled ''folder-map  = ~/.config/aerc/${lowerName account.name}-folder-map''}
                          ${lib.optionalString (account.service == "gmail.com") ''
                              cache-headers = true''}

                          ${lib.optionalString (account.service == "fastmail.com") ''
                            # https://lists.sr.ht/~rjarry/aerc-discuss/%3CD8FESFHT3XQ3.O21TH7KHQBOU@fastmail.com%3E#%3CD8FV5SWTKJNG.8IHCST9O3ZVR@fastmail.com%3E
                            use-labels        = true
                            cache-state       = true
                            cache-blobs       = true
                            use-envelope-from = true
                            carddav-source = https://${account.email}@carddav.fastmail.com/dav/addressbooks/user/${account.email}/Default
                            carddav-source-cred-cmd = ${lib.optionalString (account.carddav != null) account.carddav.cred_cmd}
                            address-book-cmd = carddav-query -S ${lowerName account.name} %s''}

                          # [notmuch]
                          # source            = notmuch://~/.mail/
                          # query-map         = ~/.config/aerc/querymap''
                      )
                      cfg.accounts
                    );
                  };

                  # This is the exact same as in `mail.nix`
                  ".config/notmuch/config" = {
                    text = let
                      # Get all emails except the primary (first account)
                      otherEmails = lib.tail (map (acc: acc.email) cfg.accounts);
                    in ''
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
                      primary_email=${primaryAccount.email}
                      ${lib.optionalString (otherEmails != []) ''
                        # https://notmuchmail.org/pipermail/notmuch/2010/003628.html
                        other_email=${lib.concatStringsSep ";" otherEmails}''}

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

                  ".config/msmtp/config" = {
                    text = ''
                      # ${nix_managed}

                      defaults
                      protocol smtp
                      auth on
                      tls on
                      tls_trust_file /etc/ssl/certs/ca-certificates.crt
                      logfile ~/Library/Logs/msmtp.log

                      ${lib.concatStringsSep "\n" (
                        lib.map (
                          account: ''
                            account ${lowerName account.name}
                            ${lib.optionalString (account.service != "gmail.com") "tls_starttls on"}
                            port 587
                            host ${account.smtp.server}
                            from ${account.email}
                            user ${account.email}
                            passwordeval ${account.smtp.password_cmd}''
                        )
                        cfg.accounts
                      )}

                      account default : ${lowerName primaryAccount.name}'';
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

                      ${lib.concatStringsSep "\n\n" (
                        map (
                          account: let
                            lower = lowerName account.name;
                          in ''
                            ########################################
                            # ${account.name}
                            ########################################
                            IMAPAccount ${account.name}
                            PipelineDepth 100
                            Host ${account.imap.server}
                            User ${account.email}
                            # Get the account password from the system Keychain
                            PassCmd "${account.imap.password_cmd}"
                            AuthMechs LOGIN
                            TLSType IMAPS
                            TLSVersions +1.2
                            ${lib.optionalString (account.service == "gmail.com") ''PipelineDepth 1''}

                            # Remote storage (where the mail is retrieved from)
                            IMAPStore ${account.name}-remote
                            Account ${account.name}

                            # Local storage (where the mail is retrieved to)
                            MaildirStore ${account.name}-local
                            Path ~/.mail/${account.name}/ # The trailing "/" is important
                            Inbox ~/.mail/${account.name}/INBOX
                            SubFolders Verbatim

                            ${lib.concatStringsSep "\n\n" (
                              map (folder: ''
                                Channel ${lower}-${lib.toLower folder.name}
                                Far :${account.name}-remote:${folder.remote}
                                Near :${account.name}-local:${folder.name}'')
                              account.mbsync.folders
                            )}

                            Channel ${lower}-folders
                            Far :${account.name}-remote:
                            Near :${account.name}-local:
                            # All folders except those defined above
                            Patterns * ${lib.concatMapStringsSep " " (f: "!${f.remote}") account.mbsync.folders}${lib.optionalString (account.mbsync.extra_exclusion_patterns != "") " ${account.mbsync.extra_exclusion_patterns}"}

                            # Group the channels, so that all channels can be sync'd with `mbsync ${lower}`
                            Group ${lower}
                            ${lib.concatMapStringsSep "\n" (f: "Channel ${lower}-${lib.toLower f.name}") account.mbsync.folders}
                            Channel ${lower}-folders

                            # For doing a quick sync of just the INBOX with `mbsync ${lower}-download`.
                            Channel ${lower}-download
                            Far :${account.name}-remote:INBOX
                            Near :${account.name}-local:INBOX
                            Create Near
                            Expunge Near
                            Sync Pull''
                        )
                        cfg.accounts
                      )}'';
                  };
                };
              };
            }
          ]
        );
    };
in {
  flake.modules.darwin.mail = mailModule;
  flake.modules.nixos.mail = mailModule;
}
