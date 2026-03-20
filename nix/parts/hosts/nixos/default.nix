{inputs, ...}: let
  host = inputs.self.lib.mkNixos "x86_64-linux" "nixos";
  m = inputs.self.modules;
  hm = m.homeManager;

  hostConfiguration = {
    config,
    pkgs,
    lib,
    inputs,
    ...
  }: {
    imports = [
      ./hardware-configuration.nix
    ];

    my = {
      user = {
        isNormalUser = true;
        extraGroups = ["wheel" "networkmanager"];
      };
    };

    nix = {
      settings."use-xdg-base-directories" = true;
      gc = {dates = "daily";};
      autoOptimiseStore = true;
      registry = {
        nixos.flake = inputs.nixpkgs;
        nixpkgs.flake = inputs.nixpkgs;
      };
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking = {
      hostName = "nixos";
      wireless.enable = false;
      networkmanager.enable = true;
      useDHCP = false;
      interfaces.enp0s20u2.useDHCP = true;
    };

    hardware.bluetooth.enable = true;
    hardware.pulseaudio = {
      enable = true;
      systemWide = true;
      support32Bit = true;
      package = pkgs.pulseaudioFull;
    };

    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {LC_TIME = "en_GB.UTF-8";};
    };

    console = {
      font = "PragmataPro Mono Liga16";
      keyMap = "us";
    };

    services = {
      xserver = {
        enable = true;
        layout = "us,ar,nl";
        libinput = {
          enable = true;
          touchpad = {
            tapping = true;
            naturalScrolling = true;
          };
        };
        windowManager.dwm.enable = true;
        windowManager.i3 = {
          enable = true;
          package = pkgs.i3-gaps;
          extraPackages = with pkgs; [i3lock dmenu i3blocks];
        };
        displayManager.defaultSession = "none+i3";
        displayManager.sddm.enable = true;
        desktopManager.plasma5.enable = true;
      };

      nextdns.enable = true;
      printing.enable = true;
      openssh.enable = true;
      tailscale.enable = true;
      avahi.enable = true;
    };

    nixpkgs.config.dwm.patches = [./dwm.patch];

    sound.enable = true;

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
      gnupg.agent = {pinentryFlavor = "pinentry";};
      java.enable = true;
      less.enable = true;
      mosh.enable = true;
      npm.enable = true;
      wireshark.enable = true;
    };
  };

  systemImports = [
    m.nixos.system-common
    m.nixos.system-base
    m.nixos.shell
    m.generic.git
    m.generic.jujutsu
    m.generic.ssh
    m.generic.bat
    m.generic.yazi
    m.generic.ripgrep
    m.generic.tmux
    m.generic.misc
    m.generic.node
    m.generic.go
    m.generic.rust
    m.generic.python
    m.generic.agenix
    m.nixos.vim
    m.nixos.gui
    m.generic.ai
    m.nixos.mail
    m.nixos.mpv
    m.nixos.kitty
    m.generic.zk
    m.nixos.discord
    m.generic."yt-dlp"
    ({config, ...}: {
      home-manager.users."${config.my.username}".imports = [
        hm.shell
        hm.ssh
        hm.git
        hm.bat
        hm.ripgrep
        hm.yazi
        hm.tmux
        hm.misc
        hm.python
        hm.jujutsu
        hm.vim
        hm.ai
        hm.gui
        hm.mail
        hm.zk
        hm.kitty
        hm.mpv
        hm."yt-dlp"
      ];
    })
    hostConfiguration
  ];
in {
  flake.modules.nixos.nixos = {
    imports = systemImports;
  };

  flake.nixosConfigurations = host;
}
