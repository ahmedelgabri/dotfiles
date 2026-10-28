let
  module =
    let
      mkMailSyncTimeout =
        lib: localAccounts: if lib.any (acc: acc.service == "gmail.com") localAccounts then "5m" else "2m";

      mkMailSyncCommand =
        {
          pkgs,
          lib,
          maxTimeout,
        }:
        pkgs.writeShellScript "mailsync" ''
          set -ue -o pipefail

          ${lib.getExe' pkgs.gnupg "gpg-connect-agent"}

          echo "--- Starting mail sync at $(${lib.getExe' pkgs.coreutils "date"}) ---"
          rc=0
          ${lib.getExe' pkgs.coreutils "timeout"} ${maxTimeout} ${lib.getExe pkgs.isync} -q -a || rc=$?

          echo "mbsync exited with $rc at $(${lib.getExe' pkgs.coreutils "date"})"
          exit $rc
        '';

      commonModule =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        with config.my;
        let
          cfg = config.my.modules.mail;
          homeDir = config.my.user.home;

          # Helper functions for multi-account support
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
                source = email: "https://${email}@carddav.fastmail.com/dav/addressbooks/user/${email}/Default";
              };
              map = {
                # Fastmail's remote folder names match the local maildir names,
                # so no folder-map text exists for it; enabling map on a
                # fastmail account requires setting text explicitly.
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
              };
              map = {
                enabled = false;
                text = ''
                  Drafts=Draft
                  Spam=Junk
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
                    remote = "Draft";
                  }
                  {
                    name = "Archive";
                    remote = "Archive";
                  }
                  {
                    # The server also has a plain "Spam" folder, but "Junk" is
                    # the one carrying the \Junk SPECIAL-USE flag.
                    name = "Spam";
                    remote = "Junk";
                  }
                  {
                    name = "Notes";
                    remote = "Notes";
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
            "gmail.com" = rec {
              imap = {
                server = "imap.gmail.com";
              };
              smtp = {
                server = "smtp.gmail.com";
              };
              aerc = {
                source_server = email: "imaps://${builtins.replaceStrings [ "@" ] [ "%40" ] email}@${imap.server}";
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
        in
        {
          options = with lib; {
            my.modules = {
              mail = {
                accounts = mkOption {
                  type = types.listOf (
                    types.submodule (
                      { config, ... }:
                      let
                        svcDefaults = serviceDefaults.${config.service};
                        passCmd = key: "${lib.getExe pkgs.pass} show service/email/${lib.toLower config.name}/${key}";
                      in
                      {
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
                            type = types.enum [
                              "fastmail.com"
                              "gmail.com"
                              "cirrux.me"
                            ];
                            default = "fastmail.com";
                            description = "Email service provider";
                          };

                          aliases = mkOption {
                            type = types.listOf types.str;
                            default = [ ];
                            example = [ "*@example.com" ];
                            description = "Other addresses that are you; replies keep them as From and reply-all leaves them out";
                          };

                          color = mkOption {
                            type = types.str;
                            default = "blue";
                            description = "Styleset colour for unread mail addressed to this account's domain";
                          };

                          mode = mkOption {
                            type = types.enum [
                              "local"
                              "remote"
                            ];
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
                                  default = passCmd "password";
                                  description = "Command to retrieve IMAP password";
                                };
                              };
                            };
                            default = { };
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
                                  default = passCmd "password";
                                  description = "Command to retrieve SMTP password";
                                };
                              };
                            };
                            default = { };
                          };

                          aerc = mkOption {
                            type = types.nullOr (
                              types.submodule {
                                options = {
                                  source_server = mkOption {
                                    type = types.str;
                                    default = svcDefaults.aerc.source_server config.email;
                                    description = "JMAP source server URL";
                                  };
                                  source_cred_cmd = mkOption {
                                    type = types.str;
                                    default = if config.service == "fastmail.com" then passCmd "source" else config.imap.password_cmd;
                                    description = "Command to retrieve remote source credentials";
                                  };
                                  outgoing_server = mkOption {
                                    type = types.str;
                                    default = svcDefaults.aerc.outgoing_server;
                                    description = "JMAP outgoing server URL";
                                  };
                                  outgoing_cred_cmd = mkOption {
                                    type = types.str;
                                    default = passCmd "outgoing";
                                    description = "Command to retrieve JMAP outgoing credentials";
                                  };
                                };
                              }
                            );
                            default = { };
                            description = "JMAP configuration (automatically enabled for supported services)";
                          };

                          carddav = mkOption {
                            type = types.nullOr (
                              types.submodule {
                                options = {
                                  source = mkOption {
                                    type = types.str;
                                    default = svcDefaults.carddav.source config.email;
                                    description = "CardDAV address book source URL";
                                  };
                                  cred_cmd = mkOption {
                                    type = types.str;
                                    default = passCmd "contacts";
                                    description = "Command to retrieve CardDAV credentials";
                                  };
                                };
                              }
                            );
                            default = if svcDefaults.carddav.enabled then { } else null;
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
                            default = { };
                            description = "Folder mapping configuration for aerc";
                          };

                          mbsync = mkOption {
                            type = types.submodule {
                              options = {
                                folders = mkOption {
                                  type = types.listOf (
                                    types.submodule {
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
                                    }
                                  );
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
                      }
                    )
                  );
                  default = [ { } ];
                  description = "List of email accounts (first account is primary)";
                };
              };
            };
          };

          config = {
            system.activationScripts.postActivation.text = ''
              echo ":: -> Running mail activationScript..."

              ${lib.concatStringsSep "\n" (
                map (account: ''
                  if [ ! -e "${homeDir}/.mail/${account.name}" ]; then
                    echo "Creating mail folder for account ${account.name} at ${homeDir}/.mail/${account.name}..."
                    mkdir -p ${homeDir}/.mail/${account.name}
                  fi
                '') localAccounts
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
                ];
              };
            };

          };
        };

      darwinModule =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        with config.my;
        let
          cfg = config.my.modules.mail;
          homeDir = config.my.user.home;
          inherit (config.home-manager.users."${username}") xdg;
          localAccounts = lib.filter (acc: acc.mode == "local") cfg.accounts;
        in
        {
          imports = [ commonModule ];

          config =
            with lib;
            mkIf (localAccounts != [ ]) (
              let
                maxTimeout = mkMailSyncTimeout lib localAccounts;
              in
              {
                launchd.user.agents."mailsync" = {
                  environment = {
                    GNUPGHOME = "${xdg.configHome}/gnupg";
                    SSH_AUTH_SOCK = "${xdg.configHome}/gnupg/S.gpg-agent.ssh";
                  };
                  command = mkMailSyncCommand {
                    inherit pkgs lib maxTimeout;
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

      nixosModule =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        with config.my;
        let
          cfg = config.my.modules.mail;
          inherit (config.home-manager.users."${username}") xdg;
          localAccounts = lib.filter (acc: acc.mode == "local") cfg.accounts;
          maxTimeout = mkMailSyncTimeout lib localAccounts;
          mailSyncCommand = mkMailSyncCommand {
            inherit pkgs lib maxTimeout;
          };
        in
        {
          imports = [ commonModule ];

          config =
            with lib;
            mkIf (localAccounts != [ ]) {
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
                wantedBy = [ "timers.target" ];
                timerConfig = {
                  Unit = "mailsync.service";
                  OnStartupSec = "15s";
                  OnUnitActiveSec = "2m";
                };
              };
            };
        };
    in
    {
      darwin = darwinModule;
      nixos = nixosModule;
      homeManager =
        {
          pkgs,
          lib,
          config,
          myConfig,
          ...
        }:
        let
          cfg = myConfig.modules.mail;
          homeDir = config.home.homeDirectory;
          primaryAccount = lib.head cfg.accounts;
          lowerName = account: lib.toLower account.name;
          localAccounts = lib.filter (acc: acc.mode == "local") cfg.accounts;
          remoteAccounts = lib.filter (acc: acc.mode == "remote") cfg.accounts;
          localGmailAccounts = lib.filter (
            acc: acc.mode == "local" && acc.service == "gmail.com"
          ) cfg.accounts;
          msmtpLogFile =
            if pkgs.stdenv.hostPlatform.isDarwin then
              "${homeDir}/Library/Logs/msmtp.log"
            else
              "${config.xdg.stateHome}/msmtp.log";
        in
        {
          home.file =
            (lib.optionalAttrs (lib.any (acc: acc.map.enabled) cfg.accounts) (
              lib.foldl' lib.recursiveUpdate { } (
                map (
                  acc:
                  lib.optionalAttrs acc.map.enabled {
                    ".config/aerc/${lowerName acc}-folder-map".text = acc.map.text;
                  }
                ) cfg.accounts
              )
            ))
            // config.lib.file.mkOutOfStoreTree {
              source = ../../../../config/aerc/stylesets;
              sourceRoot = "${myConfig.dotfilesDir}/config/aerc/stylesets";
              targetRoot = ".config/aerc/stylesets";
            }
            // lib.listToAttrs (
              map (
                account:
                lib.nameValuePair ".config/aerc/stylesets/${lowerName account}" {
                  text = builtins.readFile ../../../../config/aerc/stylesets/default + ''

                    "msglist_unread.To,~/@${lib.escapeRegex (lib.last (lib.splitString "@" account.email))}/.fg"=${account.color}
                  '';
                }
              ) cfg.accounts
            )
            // {
              ".config/aerc/binds.conf".text =
                builtins.readFile ../../../../config/aerc/binds.conf
                + lib.optionalString (remoteAccounts != [ ]) (
                  "\n"
                  + lib.concatStringsSep "\n" (
                    map (account: ''
                      [messages:account=${account.name}]
                      D = :delete<Enter>
                      A = :archive flat<Enter>

                      [view:account=${account.name}]
                      D = :delete<Enter>
                      A = :archive flat<Enter>
                    '') remoteAccounts
                  )
                )
                # Gmail has no archive folder: archiving means dropping the
                # INBOX label while the message stays in All Mail. For a
                # synced Gmail account that is a plain delete from the local
                # INBOX, which mbsync propagates as an expunge; a move to
                # Archive would instead create a Gmail label of that name.
                + lib.optionalString (localGmailAccounts != [ ]) (
                  "\n"
                  + lib.concatStringsSep "\n" (
                    map (account: ''
                      [messages:account=${account.name}]
                      A = :delete<Enter>

                      [view:account=${account.name}]
                      A = :delete<Enter>
                    '') localGmailAccounts
                  )
                );

              # Each account gets its own styleset so unread mail sent to the
              # account's domain (rather than a list or alias) carries the
              # account colour; aerc.conf gains the contextual sections that
              # select them, so it is generated like binds.conf.
              ".config/aerc/aerc.conf".text =
                lib.replaceStrings
                  [ "[hooks]\n" ]
                  [
                    (
                      # Start with the sidebar hidden on every account tab; `b`
                      # brings it back. aerc has no setting for this and
                      # :toggle-sidebar only acts on the current tab, so the
                      # startup hook walks the tabs once and ends where it began.
                      ''
                        [hooks]
                        aerc-startup=${
                          lib.concatMapStringsSep " && " (
                            _: "$AERC_BINARY :toggle-sidebar && $AERC_BINARY :next-tab"
                          ) cfg.accounts
                        }
                      ''
                      # Push moves, flags, and sent mail to the server now
                      # instead of waiting for the next sync tick. Only hosts
                      # with a local account run the sync job; elsewhere
                      # `mailsync-now` has nothing to start and fails.
                      + lib.optionalString (localAccounts != [ ]) ''
                        mail-deleted=mailsync-now
                        flag-changed=mailsync-now
                        mail-sent=mailsync-now
                        aerc-shutdown=mailsync-now
                      ''
                    )
                  ]
                  (builtins.readFile ../../../../config/aerc/aerc.conf)
                + "\n"
                + lib.concatMapStringsSep "\n" (account: ''
                  [ui:account=${account.name}]
                  styleset-name=${lowerName account}
                '') cfg.accounts;

              ".config/aerc/accounts.conf".text = lib.concatStringsSep "\n" (
                map (account: ''
                  [${account.name}]
                  from              = ${myConfig.name} <${account.email}>
                  ${
                    if account.mode == "local" then
                      "source            = maildir://~/.mail/${account.name}"
                    else
                      "source            = ${account.aerc.source_server}"
                  }
                   ${lib.optionalString (
                     account.mode == "remote"
                   ) "source-cred-cmd   = ${account.aerc.source_cred_cmd}"}
                  outgoing = msmtp -a ${lowerName account}
                  ${lib.optionalString (account.aliases != [ ])
                    "aliases           = ${
                      lib.concatMapStringsSep ", " (alias: "${myConfig.name} <${alias}>") account.aliases
                    }"
                  }
                  copy-to           = Sent
                  postpone          = Drafts
                  archive           = Archive
                  default           = INBOX
                  folders-sort      = INBOX, Starred, Drafts, Sent, Trash, Archive, Spam
                  ${lib.optionalString account.map.enabled "folder-map  = ~/.config/aerc/${lowerName account}-folder-map"}
                  ${lib.optionalString (account.service == "gmail.com") "cache-headers = true"}

                  ${lib.optionalString (account.service == "fastmail.com") ''
                    use-labels        = true
                    cache-state       = true
                    cache-blobs       = true
                    use-envelope-from = true
                    ${lib.optionalString (account.carddav != null) "carddav-source = ${account.carddav.source}"}
                    carddav-source-cred-cmd = ${lib.optionalString (account.carddav != null) account.carddav.cred_cmd}
                    address-book-cmd = carddav-query -S ${lowerName account} %s''}
                '') cfg.accounts
              );

              ".config/msmtp/config".text = ''
                # ${myConfig.nix_managed}

                defaults
                protocol smtp
                auth on
                tls on
                tls_trust_file /etc/ssl/certs/ca-certificates.crt
                logfile ${msmtpLogFile}

                ${lib.concatStringsSep "\n" (
                  lib.map (account: ''
                    account ${lowerName account}
                    ${lib.optionalString (account.service != "gmail.com") "tls_starttls on"}
                    port 587
                    host ${account.smtp.server}
                    from ${account.email}
                    user ${account.email}
                    passwordeval ${account.smtp.password_cmd}'') cfg.accounts
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
                    account:
                    let
                      lower = lowerName account;
                    in
                    ''
                      IMAPAccount ${account.name}
                      PipelineDepth 100
                      Host ${account.imap.server}
                      User ${account.email}
                      PassCmd "${account.imap.password_cmd}"
                      AuthMechs LOGIN
                      TLSType IMAPS
                      TLSVersions +1.2
                      ${lib.optionalString (account.service == "gmail.com") "PipelineDepth 1"}

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
                          Near :${account.name}-local:${folder.name}'') account.mbsync.folders
                      )}

                      Channel ${lower}-folders
                      Far :${account.name}-remote:
                      Near :${account.name}-local:
                      Patterns * ${
                        # Also exclude the local names: patterns match near-side
                        # boxes too, so without them the catch-all channel
                        # re-pairs the mapped channels' local folders.
                        lib.concatStringsSep " " (
                          lib.unique (
                            lib.concatMap (f: [
                              "!${f.remote}"
                              "!${f.name}"
                            ]) account.mbsync.folders
                          )
                        )
                      }${
                        lib.optionalString (
                          account.mbsync.extra_exclusion_patterns != ""
                        ) " ${account.mbsync.extra_exclusion_patterns}"
                      }

                      Group ${lower}
                      ${lib.concatMapStringsSep "\n" (f: "Channel ${lower}-${lib.toLower f.name}") account.mbsync.folders}
                      Channel ${lower}-folders

                      Channel ${lower}-download
                      Far :${account.name}-remote:INBOX
                      Near :${account.name}-local:INBOX
                      Create Near
                      Expunge Near
                      Sync Pull''
                  ) localAccounts
                )}'';
            };
        };
    };
in
{
  flake = {
    modules = {
      darwin.mail = module.darwin;
      nixos.mail = module.nixos;
      homeManager.mail = module.homeManager;
    };
  };
}
