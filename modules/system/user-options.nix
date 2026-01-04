# User options - defines config.my.* options for personal configuration
# These options are available in both Darwin and NixOS configurations
{lib, ...}:
with lib; let
  userOptionsModule = {
    config,
    pkgs,
    options,
    ...
  }: let
    mkOptStr = value:
      mkOption {
        type = with types; uniq str;
        default = value;
      };

    mkOpt = type: default: mkOption {inherit type default;};

    mkOpt' = type: default: description:
      mkOption {inherit type default description;};

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
        company = mkOptStr "";
        devFolder = mkOptStr "code";
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
          apply = mapAttrs (k: v:
            if isList v
            then
              if k == "TERMINFO_DIRS"
              then "$TERMINFO_DIRS:" + concatMapStringsSep ":" toString v
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

      environment.extraInit =
        concatStringsSep "\n"
        (mapAttrsToList (n: v: ''export ${n}="${v}"'') config.my.env);
    };
  };
in {
  flake.modules.darwin.user-options = userOptionsModule;
  flake.modules.nixos.user-options = userOptionsModule;
}
