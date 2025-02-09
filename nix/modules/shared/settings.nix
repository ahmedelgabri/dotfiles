{
  config,
  pkgs,
  lib,
  options,
  ...
}:
with lib; let
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

  mkOpt = type: default: mkOption {inherit type default;};

  mkOpt' = type: default: description:
    mkOption {inherit type default description;};

  mkBoolOpt = default:
    mkOption {
      inherit default;
      type = types.bool;
      example = true;
    };

  home =
    if pkgs.stdenv.isDarwin
    then "/Users/${config.my.username}"
    else "/home/${config.my.username}";
in {
  options = with types; {
    my = {
      name = mkOptStr "Ahmed El Gabri";
      timezone = mkOptStr "Europe/Amsterdam";
      username = mkOptStr "ahmed";
      website = mkOptStr "https://gabri.me";
      github_username = mkOptStr "ahmedelgabri";
      email = mkOptStr "ahmed@gabri.me";
      # NOTE: Change this?
      devFolder = mkOptStr "Sites";
      nix_managed =
        mkOptStr
        "vim: set nomodifiable : Nix managed - DO NOT EDIT - see source inside ~/.dotfiles or use `:set modifiable` to force.";
      user = mkOption {type = options.users.users.type.functor.payload.elemType;};
      hostConfigHome = mkOptStr "";
      hm = {
        file = mkOpt' attrs {} "Files to place directly in $HOME";
        cacheHome = mkOpt' path "${home}/.cache" "Absolute path to directory holding application caches.";
        configFile = mkOpt' attrs {} "Files to place in $XDG_CONFIG_HOME";
        configHome = mkOpt' path "${home}/.config" "Absolute path to directory holding application configurations.";
        dataFile = mkOpt' attrs {} "Files to place in $XDG_DATA_HOME";
        dataHome = mkOpt' path "${home}/.local/share" "Absolute path to directory holding application data.";
        stateHome = mkOpt' path "${home}/.local/state" "Absolute path to directory holding application states.";
      };
      env = mkOption {
        type = attrsOf (oneOf [str path (listOf (either str path))]);
        apply = mapAttrs (n: v:
          if isList v
          then
            if n == "TERMINFO_DIRS"
            then
              # Home-manager and sets it before nix-darwin so instead of overriding it we append to it
              "$TERMINFO_DIRS:" + concatMapStringsSep ":" toString v
            else concatMapStringsSep ":" toString v
          else (toString v));
        default = {};
        description = "Set environment variables";
      };
    };
  };

  config = {
    users.users."${config.my.username}" = mkAliasDefinitions options.my.user;
    my.user = {
      inherit home;
      description = "Primary user account";
    };

    my.hostConfigHome = "${config.my.hm.dataHome}/${config.networking.hostName}";

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bk";
    };

    # I only need a subset of home-manager's capabilities. That is, access to
    # its home.file, home.xdg.configFile and home.xdg.dataFile so I can deploy
    # files easily to my $HOME, but 'home-manager.users.${config.my.username}.home.file.*'
    # is much too long and harder to maintain, so I've made aliases in:
    #
    #   my.hm.file        ->  home-manager.users.ahmed.home.file
    #   my.hm.configFile  ->  home-manager.users.ahmed.home.xdg.configFile
    #   my.hm.dataFile    ->  home-manager.users.ahmed.home.xdg.dataFile
    home-manager.users."${config.my.username}" = {
      xdg = {
        enable = true;
        cacheHome = mkAliasDefinitions options.my.hm.cacheHome;
        configFile = mkAliasDefinitions options.my.hm.configFile;
        # configHome = mkAliasDefinitions options.my.hm.configHome;
        dataFile = mkAliasDefinitions options.my.hm.dataFile;
        # dataHome = mkAliasDefinitions options.my.hm.dataHome;
        # stateHome = mkAliasDefinitions options.my.hm.stateHome;
      };

      home = {
        inherit (config.my) username;
        file = mkAliasDefinitions options.my.hm.file;
      };

      programs = {
        # Let Home Manager install and manage itself.
        home-manager.enable = true;
        man.enable = true;
      };

      manual = {
        html.enable = true; # adds home-manager-help
        manpages.enable = true;
      };
    };

    environment.extraInit =
      concatStringsSep "\n"
      (mapAttrsToList (n: v: ''export ${n}="${v}"'') config.my.env);
  };
}
