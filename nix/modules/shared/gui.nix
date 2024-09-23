{ pkgs, lib, config, options, ... }:

let

  cfg = config.my.modules.gui;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

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
      (if (builtins.hasAttr "homebrew" options) then {
        homebrew.taps = [ "homebrew/cask-versions" ];
        homebrew.casks = [
          "1password"
          "raycast"
          "anki"
          "arc"
          "appcleaner"
          "corelocationcli"
          "brave-browser"
          "firefox"
          # "google-chrome"
          "hammerspoon"
          "imageoptim"
          "kap"
          "launchcontrol"
          "obsidian"
          "slack"
          "sync"
          "zoom"
          "visual-studio-code"
        ];

        my.hm.file = {
          ".hammerspoon" = {
            recursive = true;
            source = ../../../config/.hammerspoon;
          };
        };
      } else {
        my.user = {
          packages = with pkgs; [
            anki
            brave
            firefox
            obsidian
            zoom-us
            signal-desktop
            vscodium
            slack
            docker
            # sqlitebrowser
            # virtualbox
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
                  # https://mozilla.github.io/normandy/
                  # Disable Normandy, telemetry study stuff
                  "app.normandy.enabled" = false;
                  "app.normandy.api_url" = "";
                  "app.shield.optoutstudies.enabled" = false;
                  "app.update.auto" = true;
                  "beacon.enabled" = false;
                  "browser.aboutConfig.showWarning" = false;
                  "browser.bookmarks.showMobileBookmarks" = true;
                  "browser.contentblocking.category" = "strict";
                  "browser.ctrlTab.recentlyUsedOrder" = false;
                  "browser.discovery.enabled" = false;
                  "browser.download.alwaysOpenPanel" = false;
                  "browser.formfill.enable" = false;
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
                  "browser.safebrowsing.downloads.remote.enabled" = false;
                  "browser.safebrowsing.downloads.remote.url" = "";
                  "browser.search.countryCode" = "US";
                  "browser.search.isUS" = false;
                  "browser.search.region" = "US";
                  "browser.search.suggest.enabled" = true;
                  "browser.sessionstore.warnOnQuit" = true;
                  "browser.shell.checkDefaultBrowser" = false;
                  "browser.startup.homepage" = "about:blank";
                  "browser.tabs.inTitlebar" = 2;
                  "browser.tabs.warnOnClose" = false;
                  "browser.theme.dark-private-windows" = true;
                  "browser.toolbars.bookmarks.visibility" = "always";
                  "browser.uidensity" = 0;
                  "browser.urlbar.placeholderName" = "DuckDuckGo";
                  "browser.urlbar.trimURLs" = false;
                  "browser.urlbar.update" = true;
                  "browser.xul.error_pages.expert_bad_cert" = true;
                  "cookiebanners.ui.desktop.enabled" = true;
                  "datareporting.healthreport.service.enabled" = false;
                  "datareporting.healthreport.uploadEnabled" = false;
                  "datareporting.policy.dataSubmissionEnabled" = false;
                  "devtools.theme" = "auto";
                  "devtools.toolbox.host" = "bottom";
                  "distribution.searchplugins.defaultLocale" = "en-US";
                  "dom.disable_window_move_resize" = true;
                  "dom.forms.autocomplete.formautofill" = false;
                  "dom.payments.defaults.saveAddress" = false;
                  "dom.security.https_only_mode" = true;
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
                  "general.useragent.locale" = "en-US";
                  "general.smoothScroll" = false;
                  "identity.fxaccounts.account.device.name" = config.networking.hostName;
                  "privacy.clearOnShutdown.cache" = true;
                  "privacy.clearOnShutdown.cookies" = false;
                  "privacy.clearOnShutdown.downloads" = true;
                  "privacy.clearOnShutdown.formdata" = true;
                  "privacy.clearOnShutdown.history" = false;
                  "privacy.clearOnShutdown.sessions" = false;
                  "privacy.donottrackheader.enabled" = true;
                  "privacy.donottrackheader.value" = 1;
                  "privacy.trackingprotection.cryptomining.enabled" = true;
                  "privacy.trackingprotection.enabled" = true;
                  "privacy.trackingprotection.fingerprinting.enabled" = true;
                  "privacy.trackingprotection.socialtracking.annotate.enabled" = true;
                  "privacy.trackingprotection.socialtracking.enabled" = true;
                  "privacy.sanitize.sanitizeOnShutdown" = true;
                  "privacy.userContext.enabled" = true;
                  "privacy.userContext.ui.enabled" = true;
                  "privacy.window.name.update.enabled" = true;
                  "reader.color_scheme" = "auto";
                  "services.sync.engine.addons" = true;
                  "services.sync.engine.passwords" = true;
                  "services.sync.engine.prefs" = true;
                  "services.sync.engineStatusChanged.addons" = true;
                  "services.sync.engineStatusChanged.prefs" = true;
                  "signon.rememberSignons" = true;
                  "signon.autofillForms" = false;
                  "signon.formlessCapture.enabled" = false;
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
