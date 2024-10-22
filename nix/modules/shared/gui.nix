{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.gui;
  inherit (pkgs.stdenv) isDarwin isLinux;

in
{
  options = with lib; {
    my.modules.gui = {
      enable = mkEnableOption ''
        Whether to enable gui module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (mkIf isDarwin {
        homebrew.taps = [ "homebrew/cask-versions" ];
        homebrew.casks = [
          "1password"
          "raycast"
          "anki"
          "appcleaner"
          "corelocationcli"
          "firefox"
          "imageoptim"
          "kap"
          "launchcontrol"
          "obsidian"
          "slack"
          "sync"
          "zoom"
          "visual-studio-code"
        ];
      })
      (mkIf isLinux {
        my.user = {
          packages = with pkgs; [
            # _1password-gui # broken
            # anki # broken
            docker
            firefox
            # sqlitebrowser
            brave
            docker
            firefox
            obsidian
            signal-desktop
            slack
            vscode
            vscodium
            zoom-us
          ];
        };
      })

      {
        home-manager.users."${config.my.username}" = {
          # @BUG: NOT WORKING RIGHT NOW https://github.com/nix-community/home-manager/issues/5717
          programs.firefox = {
            enable = false;
            package =
              if isDarwin then
              # NOTE: firefox install is handled via homebrew
                pkgs.runCommand "firefox-0.0.0" { } "mkdir $out"
              else
                pkgs.firefox;

            profiles = {
              "${config.my.username}" = {
                isDefault = true;
                id = 0;
                search = {
                  default = "Google";
                  privateDefault = "DuckDuckGo";
                  force = true;
                  engines = {
                    "Nix Packages" = {
                      urls = [{
                        template = "https://search.nixos.org/packages";
                        params = [
                          { name = "type"; value = "packages"; }
                          { name = "query"; value = "{searchTerms}"; }
                        ];
                      }];

                      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                      definedAliases = [ "@np" ];
                    };

                    "NixOS Wiki" = {
                      urls = [{ template = "https://wiki.nixos.org/index.php?search={searchTerms}"; }];
                      iconUpdateURL = "https://wiki.nixos.org/favicon.png";
                      updateInterval = 24 * 60 * 60 * 1000; # every day
                      definedAliases = [ "@nw" ];
                    };

                    "Qwant".metaData.hidden = true;
                    "Ebay".metaData.hidden = true;
                    "Google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
                  };
                };


                # NOTE: WILL OVERRIDE ALL CURRENT BOOKMARKS
                # bookmarks = [
                #   {
                #     name = "wikipedia";
                #     tags = [ "wiki" ];
                #     keyword = "wiki";
                #     url = "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
                #   }
                #   {
                #     name = "kernel.org";
                #     url = "https://www.kernel.org";
                #   }
                #   {
                #     name = "Nix sites";
                #     toolbar = true;
                #     bookmarks = [
                #       {
                #         name = "homepage";
                #         url = "https://nixos.org/";
                #       }
                #       {
                #         name = "wiki";
                #         tags = [ "wiki" "nix" ];
                #         url = "https://wiki.nixos.org/";
                #       }
                #     ];
                #   }
                # ];

                containersForce = true;
                containers = {
                  work = {
                    color = "red";
                    icon = "fruit";
                    id = 2;
                  };
                  shopping = {
                    color = "blue";
                    icon = "cart";
                    id = 1;
                  };
                };

                userChrome = builtins.readFile ../../../config/firefox/chrome/userChrome.css;
                userContent = builtins.readFile ../../../config/firefox/chrome/userChrome.css;

                # @NOTE: THESE ARE CURRENTLY WORK ONLY, I NEED TO MAKE IT DYNAMIC
                # ALSO IT INSTALLS THEM BUT DOESN'T ENABLE THEM
                extensions = with pkgs.nur.repos.rycee.firefox-addons;
                  [
                    ublock-origin
                    onepassword-password-manager
                    ghostery
                    grammarly
                    notifier-for-github
                    okta-browser-plugin
                    omnivore
                    sidebery
                    sponsorblock

                    multi-account-containers

                    # @NOTE: DO I NEED THESE WITH userChrome.css and userPerfs.js???
                    stylus
                    violentmonkey

                    # @NOTE Missing
                    # wikipedia-reading-list
                    # omnivore-list-popup
                  ];


                # @NOTE: I NEED TO REVISE THIS FOR PERSONAL USE
                settings = {
                  "accessibility.typeaheadfind.flashBar" = 0;
                  # https://mozilla.github.io/normandy/
                  # Disable Normandy, telemetry study stuff
                  "app.normandy.enabled" = false;
                  "app.normandy.api_url" = "";
                  "app.shield.optoutstudies.enabled" = false;
                  "app.update.auto" = true;
                  "beacon.enabled" = false;
                  "browser.aboutConfig.showWarning" = false;
                  "browser.bookmarks.showMobileBookmarks" = true;
                  "browser.bookmarks.editDialog.confirmationHintShowCount" = 3;
                  "browser.compactmode.show" = true;
                  "browser.contentblocking.category" = "strict";
                  "browser.contentblocking.report.hide_vpn_banner" = true;
                  "browser.ctrlTab.recentlyUsedOrder" = false;
                  "browser.discovery.enabled" = false;
                  "browser.download.panel.shown" = true;
                  "browser.formfill.enable" = false;
                  "browser.ml.chat.enabled" = true;
                  "browser.ml.chat.provider" = "https://claude.ai/new";
                  "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
                  "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
                  "browser.newtabpage.activity-stream.feeds.snippets" = false;
                  "browser.newtabpage.activity-stream.feeds.telemetry" = false;
                  "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
                  "browser.newtabpage.activity-stream.showSponsored" = false;
                  "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
                  "browser.newtabpage.activity-stream.telemetry" = false;
                  "browser.newtabpage.enabled" = false;
                  "browser.ping-centre.telemetry" = false;
                  "browser.privatebrowsing.forceMediaMemoryCache" = true;
                  "browser.profiles.enabled" = true;
                  "browser.safebrowsing.downloads.remote.enabled" = false;
                  "browser.safebrowsing.downloads.remote.url" = "";
                  "browser.search.countryCode" = "US";
                  "browser.search.isUS" = false;
                  "browser.search.region" = "US";
                  "browser.search.suggest.enabled" = true;
                  "browser.sessionstore.warnOnQuit" = true;
                  "browser.shell.checkDefaultBrowser" = false;
                  "browser.startup.homepage" = "about:blank";
                  "browser.tabs.inTitlebar" = 1;
                  "browser.theme.content-theme" = 0;
                  "browser.theme.toolbar-theme" = 0;
                  "browser.tabs.warnOnClose" = false;
                  "browser.theme.dark-private-windows" = true;
                  "browser.toolbars.bookmarks.visibility" = "never";
                  "browser.translations.panelShown" = true;
                  "browser.uidensity" = 0;
                  "browser.urlbar.suggest.calculator" = true;
                  "browser.urlbar.unitConversion.enabled" = true;
                  "browser.urlbar.placeholderName" = "DuckDuckGo";
                  "browser.urlbar.quicksuggest.scenario" = "history";
                  "browser.urlbar.trimURLs" = false;
                  "browser.urlbar.update" = true;
                  "browser.xul.error_pages.expert_bad_cert" = true;
                  "cookiebanners.ui.desktop.enabled" = true;
                  "datareporting.healthreport.service.enabled" = false;
                  "datareporting.healthreport.uploadEnabled" = false;
                  "datareporting.policy.dataSubmissionEnabled" = false;
                  "devtools.cache.disabled" = true;
                  "devtools.chrome.enabled" = true;
                  "devtools.command-button-measure.enabled" = true;
                  "devtools.command-button-rulers.enabled" = true;
                  "devtools.custom-formatters.enabled" = true;
                  "devtools.debugger.features.windowless-service-workers" = true;
                  "devtools.inspector.showUserAgentStyles" = true;
                  "devtools.inspector.simple-highlighters.message-dismissed" = true;
                  "devtools.toolbox.tabsOrder" = "inspector,webconsole,jsdebugger,netmonitor,styleeditor,performance,memory,storage,accessibility,application,dom";
                  "devtools.webconsole.input.editorOnboarding" = false;
                  "devtools.theme" = "auto";
                  "devtools.toolbox.host" = "bottom";
                  "distribution.searchplugins.defaultLocale" = "en-US";
                  "doh-rollout.disable-heuristics" = true;
                  "dom.disable_window_move_resize" = true;
                  "dom.forms.autocomplete.formautofill" = false;
                  "dom.payments.defaults.saveAddress" = false;
                  "dom.security.https_only_mode" = true;
                  "dom.security.https_only_mode_ever_enabled" = true;
                  "dom.storage.next_gen" = true;
                  "extensions.formautofill.addresses.enabled" = false;
                  "extensions.formautofill.available" = "off";
                  "extensions.formautofill.creditCards.available" = false;
                  "extensions.formautofill.creditCards.enabled" = false;
                  "extensions.formautofill.heuristics.enabled" = false;
                  "extensions.getAddons.cache.enabled" = false;
                  "extensions.getAddons.showPane" = false;
                  "extensions.htmlaboutaddons.recommendations.enabled" = false;
                  "extensions.pocket.enabled" = false;
                  "extensions.webservice.discoverURL" = "";
                  "findbar.highlightAll" = true;
                  "font.name.monospace.x-western" = "PragmataPro";
                  "general.useragent.locale" = "en-US";
                  "general.smoothScroll" = false;
                  "identity.fxaccounts.account.device.name" = config.networking.hostName;
                  "identity.fxaccounts.toolbar.accessed" = true;
                  "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = true;
                  "privacy.clearOnShutdown.cache" = true;
                  "privacy.clearOnShutdown.cookies" = false;
                  "privacy.clearOnShutdown.downloads" = true;
                  "privacy.clearOnShutdown.formdata" = true;
                  "privacy.clearOnShutdown.history" = false;
                  "privacy.clearOnShutdown.sessions" = false;
                  "privacy.donottrackheader.enabled" = true;
                  "privacy.donottrackheader.value" = 1;
                  "privacy.fingerprintingProtection" = true;
                  "privacy.fingerprintingProtection.overrides" = "-FontVisibilityBaseSystem,-FontVisibilityLangPack";
                  "privacy.globalprivacycontrol.enabled" = true;
                  "privacy.query_stripping.enabled" = true;
                  "privacy.query_stripping.enabled.pbmode" = true;
                  "privacy.trackingprotection.cryptomining.enabled" = true;
                  "privacy.trackingprotection.enabled" = true;
                  "privacy.trackingprotection.emailtracking.enabled" = true;
                  "privacy.trackingprotection.fingerprinting.enabled" = true;
                  "privacy.trackingprotection.socialtracking.annotate.enabled" = true;
                  "privacy.trackingprotection.socialtracking.enabled" = true;
                  "privacy.sanitize.sanitizeOnShutdown" = true;
                  "privacy.userContext.enabled" = true;
                  "privacy.userContext.ui.enabled" = true;
                  "privacy.window.name.update.enabled" = true;
                  "reader.color_scheme" = "auto";
                  "services.sync.engine.addons" = true;
                  "services.sync.engine.creditcards" = false;
                  "services.sync.engine.passwords" = true;
                  "services.sync.engine.prefs" = true;
                  "services.sync.engineStatusChanged.addons" = true;
                  "services.sync.engineStatusChanged.prefs" = true;
                  "signon.rememberSignons" = false;
                  "signon.autofillForms" = false;
                  "signon.formlessCapture.enabled" = false;
                  "svg.context-properties.content.enabled" = true;
                  "toolkit.coverage.endpoint.base" = "";
                  "toolkit.coverage.opt-out" = true;
                  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
                  "toolkit.telemetry.archive.enabled" = false;
                  "toolkit.telemetry.bhrPing.enabled" = false;
                  "toolkit.telemetry.coverage.opt-out" = true;
                  "toolkit.telemetry.enabled" = false;
                  "toolkit.telemetry.firstShutdownPing.enabled" = false;
                  "toolkit.telemetry.newProfilePing.enabled" = false;
                  "toolkit.telemetry.rejected" = true;
                  "toolkit.telemetry.server" = "data:,";
                  "toolkit.telemetry.shutdownPingSender.enabled" = false;
                  "toolkit.telemetry.unified" = false;
                  "toolkit.telemetry.updatePing.enabled" = false;
                };
              };
            };
          };
        };
      }
    ]);
}
