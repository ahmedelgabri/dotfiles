{
  config,
  pkgs,
  inputs,
  ...
}: let
  inherit (config.my.user) home;

  xdgHomes = {
    cacheHome = "${home}/.cache";
    configHome = "${home}/.config";
    dataHome = "${home}/.local/share";
    stateHome = "${home}/.local/state";
  };
in {
  config = {
    my.hostConfigHome = "${xdgHomes.dataHome}/${config.networking.hostName}";

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bk";
      extraSpecialArgs = {
        inherit inputs;
        myConfig = {
          inherit (config.my) name email github_username company nix_managed hostConfigHome modules;
          inherit (config.networking) hostName;
        };
      };
    };

    home-manager.users."${config.my.username}" = {
      xdg = {
        enable = true;
        inherit (xdgHomes) cacheHome configHome dataHome stateHome;
      };

      home = {
        inherit (config.my) username;
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
}
