{ config, pkgs, lib, home-manager, options, ... }:

with lib;

let
  mkOptStr = value:
    mkOption {
      type = with types; uniq str;
      default = value;
    };
  mkSecret = description: default:
    mkOption {
      inherit description default;
      type = with types; either str (listOf str);
    };

in {
  options = with types; {
    my = {
      name = mkOptStr "Ahmed El Gabri";
      timezone = mkOptStr "Europe/Amsterdam";
      username = mkOptStr "ahmed";
      website = mkOptStr "https://gabri.me";
      github_username = mkOptStr "ahmedelgabri";
      email = mkOptStr "ahmed@gabri.me";
      terminal = mkOptStr "kitty";
      nix_managed = mkOptStr
        "vim: set nomodifiable : Nix managed - DO NOT EDIT - see source inside ~/.dotfiles or use `:set modifiable` to force.";
      user = mkOption { type = options.users.users.type.functor.wrapped; };
      hm = mkOption { type = options.home-manager.users.type.functor.wrapped; };
      # hm = mkOption {
      #   type = options.home-manager.users.type.functor.wrapped;
      #   default = mkOption {
      #     file = mkOption {
      #       default = { };
      #       type = attrs;
      #       description = "Files to place directly in $HOME";
      #     };
      #     configFile = mkOption {
      #       default = { };
      #       type = attrs;
      #       description = "Files to place in $XDG_CONFIG_HOME";
      #     };
      #     dataFile = mkOption {
      #       default = { };
      #       type = attrs;
      #       description = "Files to place in $XDG_DATA_HOME";
      #     };
      #     configHome = mkOption {
      #       default = users.${config.my.username}.xdg.configHome;
      #       type = path;
      #       description = "path to $XDG_CONFIG_HOME";
      #     };
      #     dataHome = mkOption {
      #       default = users.${config.my.username}.xdg.dataHome;
      #       type = attrs;
      #       description = "path to $XDG_DATA_HOME";
      #     };
      #     cacheHome = mkOption {
      #       default = users.${config.my.username}.xdg.cacheHome;
      #       type = attrs;
      #       description = "path to $XDG_CACHE_HOME";
      #     };
      #   };
      # };
      #
    };
  };

  config = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };

    # I only need a subset of home-manager's capabilities. That is, access to
    # its home.file, home.xdg.configFile and home.xdg.dataFile so I can deploy
    # files easily to my $HOME, but 'home-manager.users.${config.my.username}.home.file.*'
    # is much too long and harder to maintain, so I've made aliases in:
    #
    #   my.hm.file        ->  home-manager.users.ahmed.home.file
    #   my.hm.configFile  ->  home-manager.users.ahmed.home.xdg.configFile
    #   my.hm.dataFile    ->  home-manager.users.ahmed.home.xdg.dataFile
    home-manager.users.${config.my.username} = mkAliasDefinitions options.my.hm;

    my.hm = {
      xdg = {
        enable = true;
        # dataHome = mkAliasDefinitions options.my.hm.dataHome;
        # cacheHome = mkAliasDefinitions options.my.hm.cacheHome;
        # configFile = mkAliasDefinitions options.my.hm.configFile;
        # dataFile = mkAliasDefinitions options.my.hm.dataFile;
        # configHome = mkAliasDefinitions options.my.hm.configHome;
      };

      home = {
        # Necessary for home-manager to work with flakes, otherwise it will
        # look for a nixpkgs channel.
        stateVersion =
          if pkgs.stdenv.isDarwin then "20.09" else config.system.stateVersion;
        username = config.my.username;
        # file = mkAliasDefinitions options.my.hm.file;
      };

      programs = {
        # Let Home Manager install and manage itself.
        home-manager.enable = true;
      };
    };

    users.users.${config.my.username} = mkAliasDefinitions options.my.user;
    my.user = {
      home = if pkgs.stdenv.isDarwin then
        "/Users/${config.my.username}"
      else
        "/home/${config.my.username}";
      description = "Primary user account";
    };
  };
}
