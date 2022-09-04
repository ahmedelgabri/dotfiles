{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.macos;

in
{
  options = with lib; {
    my.modules.macos = {
      enable = mkEnableOption ''
        Whether to enable macos module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.variables = {
        LANG = "en_US.UTF-8";
        LC_TIME = "en_GB.UTF-8";
      };

      system = {
        defaults = {
          # ".GlobalPreferences".com.apple.sound.beep.sound = "Funk";
          LaunchServices.LSQuarantine = false;
          SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
          loginwindow.GuestEnabled = false;
          NSGlobalDomain = {
            AppleFontSmoothing = 2;
            AppleKeyboardUIMode = 3;
            AppleMeasurementUnits = "Centimeters";
            AppleMetricUnits = 1;
            ApplePressAndHoldEnabled = false;
            AppleShowAllExtensions = true;
            AppleShowScrollBars = "Automatic";
            AppleTemperatureUnit = "Celsius";
            InitialKeyRepeat = 10;
            KeyRepeat = 1;
            NSAutomaticCapitalizationEnabled = false;
            NSAutomaticDashSubstitutionEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
            NSAutomaticSpellingCorrectionEnabled = false;
            NSDocumentSaveNewDocumentsToCloud = false;
            NSNavPanelExpandedStateForSaveMode = true;
            NSNavPanelExpandedStateForSaveMode2 = true;
            NSTableViewDefaultSizeMode = 2;
            NSTextShowsControlCharacters = true;
            NSWindowResizeTime = 0.001;
            PMPrintingExpandedStateForPrint = true;
            PMPrintingExpandedStateForPrint2 = true;
            _HIHideMenuBar = true;
            # com.apple.mouse.tapBehavior = 1;
            # com.apple.sound.beep.feedback = 0;
            # com.apple.springing.delay = 0;
            # com.apple.springing.enabled = true;
          };

          dock = {
            autohide = true;
            autohide-delay = 0.0;
            autohide-time-modifier = 0.0;
            dashboard-in-overlay = true;
            expose-animation-duration = 0.1;
            expose-group-by-app = false;
            launchanim = false;
            mineffect = "genie";
            minimize-to-application = true;
            mouse-over-hilite-stack = true;
            show-process-indicators = false;
            show-recents = false;
            showhidden = true;
            static-only = true;
            tilesize = 32;
            # Hot corners, reset them all.
            # Not supported in nix-darwin yet
            # wvous-tl-corner = 0;
            # wvous-tl-modifier = 0;
            # wvous-tr-corner = 0;
            # wvous-tr-modifier = 0;
            # wvous-bl-corner = 0;
            # wvous-bl-modifier = 0;
            # wvous-br-corner = 0;
            # wvous-br-modifier = 0;
          };

          finder = {
            AppleShowAllExtensions = true;
            # QuitMenuItem = true;
            _FXShowPosixPathInTitle = false; # In Big Sur this is so UGLY!
          };

          trackpad = {
            Clicking = true;
            TrackpadRightClick = true;
          };
        };

        keyboard = {
          enableKeyMapping = true;
          remapCapsLockToEscape = true;
        };

      };
    };
}
