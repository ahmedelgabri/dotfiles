{ inputs, ... }:
let
  host = inputs.self.lib.mkNixos "x86_64-linux" "nixos";

  hostConfiguration =
    {
      pkgs,
      inputs,
      ...
    }:
    {
      imports = [
        ./hardware-configuration.nix
      ];

      my = {
        user = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
        };
      };

      nix = {
        settings."use-xdg-base-directories" = true;
        gc = {
          dates = "daily";
        };
        registry = {
          nixos.flake = inputs.nixpkgs;
          nixpkgs.flake = inputs.nixpkgs;
        };
      };

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking = {
        hostName = "nixos";
        networkmanager.enable = true;
        useDHCP = false;
        interfaces.enp0s20u2.useDHCP = true;
      };

      hardware.bluetooth.enable = true;
      i18n = {
        defaultLocale = "en_US.UTF-8";
        extraLocaleSettings = {
          LC_TIME = "en_GB.UTF-8";
        };
      };

      console = {
        font = "PragmataPro Mono Liga16";
        keyMap = "us";
      };

      services = {
        desktopManager.plasma6.enable = true;
        displayManager = {
          defaultSession = "none+i3";
          sddm.enable = true;
        };
        libinput = {
          enable = true;
          touchpad = {
            tapping = true;
            naturalScrolling = true;
          };
        };

        xserver = {
          enable = true;
          xkb.layout = "us,ar,nl";
          windowManager.dwm.enable = true;
          windowManager.i3 = {
            enable = true;
            package = pkgs.i3;
            extraPackages = with pkgs; [
              i3lock
              dmenu
              i3blocks
            ];
          };
        };

        nextdns.enable = true;
        printing.enable = true;
        openssh.enable = true;
        tailscale.enable = true;
        avahi.enable = true;
      };

      nixpkgs.config.dwm.patches = [ ./dwm.patch ];

      environment.systemPackages = with pkgs; [
        gnumake
        wget
        htop
        emacs
        dunst
        killall
        feh
        unzip
        wirelesstools
        libnotify
        x11
        gnome3.networkmanagerapplet
      ];

      environment.shellAliases.l = null;

      programs = {
        java.enable = true;
        less.enable = true;
        mosh.enable = true;
        npm.enable = true;
        wireshark.enable = true;
      };
    };

  systemImports = [
    (inputs.self.lib.mkFeatureModule "nixos" {
      features = [
        "system-base"
        "shell"
        "git"
        "jujutsu"
        "ssh"
        "bat"
        "yazi"
        "ripgrep"
        "tmux"
        "misc"
        "node"
        "go"
        "rust"
        "python"
        "agenix"
        "vim"
        "gui"
        "ai"
        "gpg"
        "mail"
        "mpv"
        "kitty"
        "ghostty"
        "zk"
        "discord"
        "yt-dlp"
        "bun"
      ];
    })
    hostConfiguration
  ];
in
{
  flake.modules.nixos.nixos = {
    imports = systemImports;
  };

  flake.nixosConfigurations = host;
}
