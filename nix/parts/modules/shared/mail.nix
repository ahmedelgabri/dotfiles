let
  module =
let
  mkMailSyncTimeout = lib: localAccounts:
    if lib.any (acc: acc.service == "gmail.com") localAccounts
    then "5m"
    else "2m";

  mkMailSyncCommand = {
    pkgs,
    lib,
    xdgConfigHome,
    maxTimeout,
  }:
    pkgs.writeShellScript "mailsync" ''
      set -ue -o pipefail

      ${lib.getExe' pkgs.gnupg "gpg-connect-agent"}

      echo "--- Starting mail sync at $(${lib.getExe' pkgs.coreutils "date"}) ---"
      ${lib.getExe' pkgs.coreutils "timeout"} ${maxTimeout} ${lib.getExe pkgs.isync} -q -a

      echo "mbsync finished successfully. Indexing new mail..."
      ${lib.getExe pkgs.notmuch} --config=${xdgConfigHome}/notmuch/config new

      echo "Sync finished at $(${lib.getExe' pkgs.coreutils "date"})"
    '';

  commonModule = {
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
      localAccounts = lib.filter (acc: acc.mode == "local") cfg.accounts;

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
            source_server = email: "imaps://${builtins.replaceStrings ["@"] ["%40"] email}@${imap.server}";
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

                  mode = mkOption {
                    type = types.enum ["local" "remote"];
                    default = "local";
                    description = "Whether to use local maildir (synced via mbsync) or connect to remote IMAP/JMAP directly";
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

      config = with lib; (
        mkMerge [
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
                localAccounts
              )}
            '';

            my = {
              user = {
                packages = with pkgs; [
                  aerc
                  isync
                  pass
                  msmtp
                  w3m
                  notmuch
                  urlscan
                ];
              };

              env = {
                MAILDIR = "$HOME/.mail"; # will be picked up by .notmuch-config for database.path
                NOTMUCH_CONFIG = "$XDG_CONFIG_HOME/notmuch/config";
              };
            };
          }
        ]
      );
    };

  darwinModule = {
    pkgs,
    lib,
    config,
    ...
  }:
    with config.my; let
      cfg = config.my.modules.mail;
      homeDir = config.my.user.home;
      inherit (config.home-manager.users."${username}") xdg;
      localAccounts = lib.filter (acc: acc.mode == "local") cfg.accounts;
    in {
      imports = [commonModule];

      config = with lib;
        mkIf (localAccounts != []) (
          let
            maxTimeout = mkMailSyncTimeout lib localAccounts;
          in {
            launchd.user.agents."mailsync" = {
              environment = {
                GNUPGHOME = "${xdg.configHome}/gnupg";
                SSH_AUTH_SOCK = "${xdg.configHome}/gnupg/S.gpg-agent.ssh";
              };
              command = mkMailSyncCommand {
                inherit pkgs lib maxTimeout;
                xdgConfigHome = xdg.configHome;
              };

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
          }
        );
    };

  nixosModule = {
    pkgs,
    lib,
    config,
    ...
  }:
    with config.my; let
      cfg = config.my.modules.mail;
      inherit (config.home-manager.users."${username}") xdg;
      localAccounts = lib.filter (acc: acc.mode == "local") cfg.accounts;
      maxTimeout = mkMailSyncTimeout lib localAccounts;
      mailSyncCommand = mkMailSyncCommand {
        inherit pkgs lib maxTimeout;
        xdgConfigHome = xdg.configHome;
      };
    in {
      imports = [commonModule];

      config = with lib;
        mkIf (localAccounts != []) {
          systemd.user.services.mailsync = {
            description = "Synchronize mail with mbsync";
            environment = {
              GNUPGHOME = "${xdg.configHome}/gnupg";
              SSH_AUTH_SOCK = "${xdg.configHome}/gnupg/S.gpg-agent.ssh";
              SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
            };
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${mailSyncCommand}";
              TimeoutStartSec = maxTimeout;
            };
          };

          systemd.user.timers.mailsync = {
            description = "Periodic mail sync";
            wantedBy = ["timers.target"];
            timerConfig = {
              Unit = "mailsync.service";
              OnStartupSec = "15s";
              OnUnitActiveSec = "2m";
            };
          };
        };
    };
in {
  darwin = darwinModule;
  nixos = nixosModule;
  homeManager = {
    pkgs,
    lib,
    config,
    myConfig,
    ...
  }: let
    cfg = myConfig.modules.mail;
    homeDir = config.home.homeDirectory;
    primaryAccount = lib.head cfg.accounts;
    lowerName = account: lib.toLower account.name;
    localAccounts = lib.filter (acc: acc.mode == "local") cfg.accounts;
    remoteAccounts = lib.filter (acc: acc.mode == "remote") cfg.accounts;
    otherEmails = lib.tail (map (acc: acc.email) cfg.accounts);
    msmtpLogFile =
      if pkgs.stdenv.isDarwin
      then "${homeDir}/Library/Logs/msmtp.log"
      else "${config.xdg.stateHome}/msmtp.log";
  in {
    home.file =
      (lib.optionalAttrs (lib.any (acc: acc.map.enabled) cfg.accounts) (
        lib.foldl' lib.recursiveUpdate {} (
          map (acc:
            lib.optionalAttrs acc.map.enabled {
              ".config/aerc/${lowerName acc}-folder-map".text = acc.map.text;
            })
          cfg.accounts
        )
      ))
      // {
        ".config/aerc/stylesets" = {
          recursive = true;
          source = ../../../../config/aerc/stylesets;
        };

        ".config/aerc/binds.conf".text =
          builtins.readFile ../../../../config/aerc/binds.conf
          + lib.optionalString (remoteAccounts != []) (
            "\n"
            + lib.concatStringsSep "\n" (
              map (account: ''
                [messages:account=${account.name}]
                D = :delete<Enter>
                A = :archive flat<Enter>

                [view:account=${account.name}]
                D = :delete<Enter>
                A = :archive flat<Enter>
              '')
              remoteAccounts
            )
          );

        ".config/aerc/querymap".source = ../../../../config/aerc/querymap;
        ".config/aerc/aerc.conf".source = ../../../../config/aerc/aerc.conf;

        ".config/aerc/accounts.conf".text = lib.concatStringsSep "\n" (
          map (
            account: ''
              [${account.name}]
              from              = ${myConfig.name} <${account.email}>
              ${
                if account.mode == "local"
                then "source            = maildir://~/.mail/${account.name}"
                else "source            = ${account.aerc.source_server}"
              }
               ${lib.optionalString (account.mode == "remote") "source-cred-cmd   = ${account.aerc.source_cred_cmd}"}
              outgoing = msmtp -a ${lowerName account}
              copy-to           = Sent
              postpone          = Drafts
              archive           = Archive
              default           = INBOX
              folders-sort      = INBOX, Starred, Drafts, Sent, Trash, Archive, Spam
              ${lib.optionalString account.map.enabled ''folder-map  = ~/.config/aerc/${lowerName account}-folder-map''}
              ${lib.optionalString (account.service == "gmail.com") ''
                  cache-headers = true''}

              ${lib.optionalString (account.service == "fastmail.com") ''
                use-labels        = true
                cache-state       = true
                cache-blobs       = true
                use-envelope-from = true
                carddav-source = https://${account.email}@carddav.fastmail.com/dav/addressbooks/user/${account.email}/Default
                carddav-source-cred-cmd = ${lib.optionalString (account.carddav != null) account.carddav.cred_cmd}
                address-book-cmd = carddav-query -S ${lowerName account} %s''}
            ''
          )
          cfg.accounts
        );

        ".config/notmuch/config".text = ''
          # ${myConfig.nix_managed}
          #  vim:ft=conf

          [database]
          path=${homeDir}/.mail

          [user]
          name=${myConfig.name}
          primary_email=${primaryAccount.email}
          ${lib.optionalString (otherEmails != []) ''
              other_email=${lib.concatStringsSep ";" otherEmails}''}

          [new]
          tags=unread;inbox;
          ignore=.mbsyncstate;.DS_Store;.mbsyncstate.journal;.mbsyncstate.new;.mbsyncstate.lock;.uidvalidity

          [search]
          exclude_tags=deleted;spam;trash;

          [query]
          inbox=tag:inbox and tag:unread
          sent=tag:sent
          archive=not tag:inbox
          github=tag:github or from:notifications@github.com
          urgent=tag:urgent

          [maildir]
          synchronize_flags=true

          [crypto]
          gpg_path=${lib.getExe pkgs.gnupg} '';

        ".config/msmtp/config".text = ''
          # ${myConfig.nix_managed}

          defaults
          protocol smtp
          auth on
          tls on
          tls_trust_file /etc/ssl/certs/ca-certificates.crt
          logfile ${msmtpLogFile}

          ${lib.concatStringsSep "\n" (
            lib.map (
              account: ''
                account ${lowerName account}
                ${lib.optionalString (account.service != "gmail.com") "tls_starttls on"}
                port 587
                host ${account.smtp.server}
                from ${account.email}
                user ${account.email}
                passwordeval ${account.smtp.password_cmd}''
            )
            cfg.accounts
          )}

          account default : ${lowerName primaryAccount}'';

        ".config/isyncrc".text = ''
          # ${myConfig.nix_managed}
          Create Both
          Expunge Both
          CopyArrivalDate yes
          Sync All
          Remove Near
          SyncState *

          ${lib.concatStringsSep "\n\n" (
            map (
              account: let
                lower = lowerName account;
              in ''
                IMAPAccount ${account.name}
                PipelineDepth 100
                Host ${account.imap.server}
                User ${account.email}
                PassCmd "${account.imap.password_cmd}"
                AuthMechs LOGIN
                TLSType IMAPS
                TLSVersions +1.2
                ${lib.optionalString (account.service == "gmail.com") ''PipelineDepth 1''}

                IMAPStore ${account.name}-remote
                Account ${account.name}

                MaildirStore ${account.name}-local
                Path ~/.mail/${account.name}/
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
                Patterns * ${lib.concatMapStringsSep " " (f: "!${f.remote}") account.mbsync.folders}${lib.optionalString (account.mbsync.extra_exclusion_patterns != "") " ${account.mbsync.extra_exclusion_patterns}"}

                Group ${lower}
                ${lib.concatMapStringsSep "\n" (f: "Channel ${lower}-${lib.toLower f.name}") account.mbsync.folders}
                Channel ${lower}-folders

                Channel ${lower}-download
                Far :${account.name}-remote:INBOX
                Near :${account.name}-local:INBOX
                Create Near
                Expunge Near
                Sync Pull''
            )
            localAccounts
          )}'';
      };
  };
}
  ;
in {
  flake = {
    modules = {
      darwin.mail = module.darwin;
      nixos.mail = module.nixos;
      homeManager.mail = module.homeManager;
    };
  };
}
