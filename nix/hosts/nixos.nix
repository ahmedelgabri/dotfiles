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

{ config, pkgs, lib, inputs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    config = { allowUnfree = true; };
    overlays = [
      # (import inputs.comma { inherit pkgs; })
      (final: prev: {
        neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (oldAttrs: {
          version = "master";
          src = inputs.neovim-nightly;
          buildInputs = oldAttrs.buildInputs ++ [ pkgs.tree-sitter ];
        });

        python3 = prev.python3.override {
          packageOverrides = final: prev: {
            python-language-server =
              prev.python-language-server.overridePythonAttrs
              (old: rec { doCheck = false; });
          };
        };

        # https://github.com/NixOS/nixpkgs/issues/106506#issuecomment-742639055
        weechat = prev.weechat.override {
          configure = { availablePlugins, ... }: {
            plugins = with availablePlugins;
              [ (perl.withPackages (p: [ p.PodParser ])) ] ++ [ python ];
            scripts = with prev.weechatScripts;
              [ wee-slack ]
              ++ final.stdenv.lib.optionals (!final.stdenv.isDarwin)
              [ weechat-notify-send ];
          };
        };
      })
    ];
  };

  nix = {
    gc = {
      dates = "daily";
      automatic = true;
      options = "--delete-older-than 3d";
    };
    autoOptimiseStore = true;
    binaryCaches = [
      "https://cache.nixos.org"
      # "https://nix-community.cachix.org"
      "https://nixpkgs.cachix.org"
    ];
    binaryCachePublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
    ];

    registry = {
      nixos.flake = inputs.nixpkgs;
      nixpkgs.flake = inputs.nixpkgs-unstable;
    };
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
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

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

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
      tapping = true;
      naturalScrolling = true;
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

  nixpkgs.config.dwm.patches = [ ./dwm.patch ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  environment.shells = [ pkgs.bashInteractive pkgs.zsh ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ahmed = {
    description = "Primary user account";
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    htop
    vim
    emacs
    # inputs.nixpkgs-unstable.kitty
    kitty
    git
    brave
    # tmux
    firefox
    zsh
    pure-prompt
    dunst
    killall
    # inputs.nixpkgs-unstable.feh
    feh
    # inputs.nixpkgs-unstable.neovim
    neovim-unwrapped
    unzip
    wirelesstools
    python3

    libnotify
    x11
    gnome3.networkmanagerapplet # needed for i3m to be able to use networkmanager through nm-applet
  ];

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
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "gnome3";
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      promptInit = lib.mkDefault "";
    };

    java.enable = true;
    less.enable = true;
    mosh.enable = true;
    # [todo] check if I still need gnome3.networkmanagerapplet or not
    # nm-applet = true;
    # [todo] check other options
    npm.enable = true;
    # ssh.knownHosts = {};
    # ssh.startAgent = true; # Only this or the gnupg enableSSHSupport should be enabled in the same time
    tmux.enable = true;
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
