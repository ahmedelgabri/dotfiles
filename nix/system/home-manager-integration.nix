# Home-manager integration - base configuration and XDG setup
# Sets up home-manager to work with the custom config.my.* options
{lib, ...}:
with lib; let
  homeManagerModule = {config, options, ...}: {
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
        dataFile = mkAliasDefinitions options.my.hm.dataFile;
      };

      home = {
        inherit (config.my) username;
        file = mkAliasDefinitions options.my.hm.file;
      };

      programs = {
        home-manager.enable = true;
        man.enable = true;
      };

      manual = {
        html.enable = true;
        manpages.enable = true;
      };
    };
  };
in {
  flake.modules.darwin.home-manager-integration = homeManagerModule;
  flake.modules.nixos.home-manager-integration = homeManagerModule;
}
