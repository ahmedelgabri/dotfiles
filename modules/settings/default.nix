{ config, pkgs, lib, home-manager, ... }:

with lib;

{
  options = with types; {
    # user = mkOption {
    #   default = { };
    #   type = attrs;
    # };
    #
    # home = {
    #   file = mkOption {
    #     default = { };
    #     type = attrs;
    #     description = "Files to place directly in $HOME";
    #   };
    #   configFile = mkOption {
    #     default = { };
    #     type = attrs;
    #     description = "Files to place in $XDG_CONFIG_HOME";
    #   };
    #   dataFile = mkOption {
    #     default = { };
    #     type = attrs;
    #     description = "Files to place in $XDG_DATA_HOME";
    #   };
    #   configHome = mkOption {
    #     default = users.${config.settings.username}.xdg.configHome;
    #     type = path;
    #     description = "path to $XDG_CONFIG_HOME";
    #   };
    #   dataHome = mkOption {
    #     default = users.${config.settings.username}.xdg.dataHome;
    #     type = attrs;
    #     description = "path to $XDG_DATA_HOME";
    #   };
    #   cacheHome = mkOption {
    #     default = users.${config.settings.username}.xdg.cacheHome;
    #     type = attrs;
    #     description = "path to $XDG_CACHE_HOME";
    #   };
    # };

    settings = {
      name = mkOption {
        default = "Ahmed El Gabri";
        type = uniq str;
      };
      timezone = mkOption {
        default = "Europe/Amsterdam";
        type = uniq str;
      };
      username = mkOption {
        default = "ahmed";
        type = uniq str;
      };
      website = mkOption {
        default = "https://gabri.me";
        type = uniq str;
      };
      github_username = mkOption {
        default = "ahmedelgabri";
        type = uniq str;
      };
      email = mkOption {
        default = "ahmed@gabri.me";
        type = uniq str;
      };
      terminal = mkOption {
        default = "kitty";
        type = uniq str;
      };
      nix_managed = mkOption {
        default =
          "vim: set nomodifiable : Nix managed - DO NOT EDIT - see source inside ~/.dotfiles or use `:set modifiable` to force.";
        type = uniq str;
      };
    };
  };

  # config = {
  #   user = {
  #     name = config.settings.username;
  #     description = "The primary user account";
  #     # home = "/Users/${config.settings.username}";
  #     # extraGroups = [ "wheel" ];
  #     # isNormalUser = true;
  #     # name = let name = builtins.getEnv "USER";
  #     # in if elem name [ "" "root" ] then config.settings.username else name;
  #     # uid = 1000;
  #   };
  #
  #   users.users.${config.user.name} = mkAliasDefinitions options.user;
  #
  #   home-manager = {
  #     useUserPackages = true;
  #
  #     # I only need a subset of home-manager's capabilities. That is, access to
  #     # its home.file, home.xdg.configFile and home.xdg.dataFile so I can deploy
  #     # files easily to my $HOME, but 'home-manager.users.${config.settings.username}.home.file.*'
  #     # is much too long and harder to maintain, so I've made aliases in:
  #     #
  #     #   home.file        ->  home-manager.users.ahmed.home.file
  #     #   home.configFile  ->  home-manager.users.ahmed.home.xdg.configFile
  #     #   home.dataFile    ->  home-manager.users.ahmed.home.xdg.dataFile
  #     users.${config.user.name} = {
  #       xdg = {
  #         enable = true;
  #         configHome = mkAliasDefinitions options.home.configHome;
  #         dataHome = mkAliasDefinitions options.home.dataHome;
  #         cacheHome = mkAliasDefinitions options.home.cacheHome;
  #         configFile = mkAliasDefinitions options.home.configFile;
  #         dataFile = mkAliasDefinitions options.home.dataFile;
  #       };
  #       home = {
  #         stateVersion = "20.09";
  #         username = config.settings.username;
  #         file = mkAliasDefinitions options.home.file;
  #       };
  #
  #       programs = {
  #         # Let Home Manager install and manage itself.
  #         home-manager.enable = true;
  #       };
  #     };
  #   };
  #
  # };
}
