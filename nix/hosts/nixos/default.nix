# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# Notes from MBA NixOS installation
#
# - Wifi requires network manager & this can't be enabled if wireless is enabled also
# - broadcom drivers for wifi, require allowUnfree
# - wifi requires user to be in the networkmanager group
# - bluetooth requires some setup https://nixos.wiki/wiki/Bluetooth & also running this command `systemctl --user daemon-reload; systemctl --user restart pulseaudio`
# - printf in i3blocks scripts should be replaced with echo & colors need to change too. (edits need to happen for tmux/scripts because I will use those)
# - mtui to debug network issues

# https://github.com/AbhinavGeorge/configs/blob/master/.i3/config#L274-L281

{ config, pkgs, lib, inputs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  my = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    user = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    };

    modules = {
      mail = { enable = true; };
      aerc = { enable = true; };
      youtube-dl.enable = true;
      irc.enable = true;
      rescript.enable = true;
      clojure.enable = true;
      newsboat.enable = true;
      gpg.enable = false;
    };
  };

  nix = {
    gc = { dates = "daily"; };
    autoOptimiseStore = true;
    registry = {
      nixos.flake = inputs.nixpkgs;
      nixpkgs.flake = inputs.nixpkgs-unstable;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # Enables wireless support via wpa_supplicant.
  networking.wireless.enable = false;
  # Only one needs to be enabled, this or wireless
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  hardware.pulseaudio = {
    enable = true;
    systemWide = true;
    support32Bit = true;

    # NixOS allows either a lightweight build (default) or full build of PulseAudio to be installed.
    # Only the full build has Bluetooth support, so it must be selected here.
    package = pkgs.pulseaudioFull;
  };
  # services.blueman.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s20u2.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "PragmataPro Mono Liga16";
    keyMap = "us";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    # Configure keymap in X11
    layout = "us,ar,nl";
    # xkbOptions = "eurosign:e";
    # Enable touchpad support (enabled default in most desktopManager).
    libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        naturalScrolling = true;
      };
      #      accelProfile = "flat";
      #      additionalOptions = ''MatchIsTouchpad "on"'';
    };
    windowManager.dwm.enable = true;
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      extraPackages = with pkgs; [ i3lock dmenu i3blocks ];
      # extraSessionCommands = ''
      # ${pkgs.xset}/bin/xset r rate 200 60
      # ${inputs.nixpgs-unstable.feh}/bin/feh --no-fehbg --bg-fill "/home/ahmed/.config/big-sur.jpg" &
      # ${pkgs.dunst}/bin/dunst &
      # '';
    };
    displayManager.defaultSession = "none+i3";
    # displayManager.setupCommands = ''
    # ${inputs.nixpkgs-unstable.feh}/bin/feh --no-fehbg --bg-fill "/home/ahmed/.config/big-sur.jpg" &
    # ${pkgs.dunst}/bin/dunst &
    # '';
    # displayManager.startx.enable = true;

    # Enable the Plasma 5 Desktop Environment.
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  services.nextdns.enable = true;

  nixpkgs.config.dwm.patches = [ ./dwm.patch ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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
    # python3
    libnotify
    x11
    gnome3.networkmanagerapplet # needed for i3m to be able to use networkmanager through nm-applet
  ];

  environment.shellAliases.l = null;

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    # liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts
    dina-font
    proggyfonts
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs = {
    gnupg.agent = { pinentryFlavor = "pinentry"; };

    java.enable = true;
    less.enable = true;
    mosh.enable = true;
    # [todo] check if I still need gnome3.networkmanagerapplet or not
    # nm-applet = true;
    # [todo] check other options
    npm.enable = true;
    # ssh.knownHosts = {};
    # ssh.startAgent = true; # Only this or the gnupg enableSSHSupport should be enabled in the same time
    wireshark.enable = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
