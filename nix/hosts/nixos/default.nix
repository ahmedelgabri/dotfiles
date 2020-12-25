# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix = {
    gc = { dates = "daily"; };
    autoOptimiseStore = true;
    registry = {
      nixos.flake = inputs.nixpkgs;
      nixpkgs.flake = inputs.nixpkgs-unstable;
    };
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "nixos"; # Define your hostname.
    wireless.enable = true; # Enables wireless support via wpa_supplicant.

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;
    interfaces.enp0s3.useDHCP = true;

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Open ports in the firewall.
    # firewall.allowedTCPPorts = [ ... ];
    # firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # firewall.enable = false;
  };

  # List services that you want to enable:
  services = {
    # Enable the OpenSSH daemon.
    openssh.enable = true;

    # Enable CUPS to print documents.
    printing.enable = true;

    # Enable the X11 windowing system.
    xserver = {
      enable = true;
      layout = "us,ar,nl";
      # xkbOptions = "eurosign:e";
      libinput = {
        enable = true;
        tapping = true;
        naturalScrolling = false;
        #      accelProfile = "flat";
        #      additionalOptions = ''MatchIsTouchpad "on"'';
      };
      windowManager.dwm.enable = true;
      # displayManager.defaultSession = "dwm";
      # displayManager.startx.enable = true;

      # Enable the KDE Desktop Environment.
      # displayManager.sddm.enable = true;
      # desktopManager.plasma5.enable = true;
    };
  };

  # this can be pulled from GitHub too
  # https://github.com/zoickx/dotfiles/blob/0f170f4c9bae8627021115f911fc619d5da55ff1/nixos/configuration.nix#L82-L95
  nixpkgs.config.dwm.patches = [ ./patch.diff ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "gnome3";
    };
    zsh.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${config.settings.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}
