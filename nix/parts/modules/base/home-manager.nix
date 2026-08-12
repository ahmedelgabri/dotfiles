{
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (config.my.user) home;

  xdgHomes = {
    cacheHome = "${home}/.cache";
    configHome = "${home}/.config";
    dataHome = "${home}/.local/share";
    stateHome = "${home}/.local/state";
  };
in
{
  config = {
    my.hostConfigHome = "${xdgHomes.dataHome}/${config.my.hostName}";
    my.dotfilesDir = "${home}/.dotfiles";

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bk";
      sharedModules = [
        (
          { config, lib, ... }:
          {
            # Keep destination directories writable while making each managed
            # file live-editable from the dotfiles checkout.
            lib.file.mkOutOfStoreTree =
              {
                source,
                sourceRoot,
                targetRoot,
              }:
              lib.listToAttrs (
                map (
                  file:
                  let
                    relative = lib.removePrefix "${toString source}/" (toString file);
                  in
                  lib.nameValuePair "${targetRoot}/${relative}" {
                    source = config.lib.file.mkOutOfStoreSymlink "${sourceRoot}/${relative}";
                  }
                ) (lib.filesystem.listFilesRecursive source)
              );
          }
        )
      ];
      extraSpecialArgs = {
        inherit inputs;
        myConfig = {
          inherit (config.my)
            name
            email
            github_username
            company
            nix_managed
            hostName
            hostConfigHome
            dotfilesDir
            modules
            ;
        };
      };
    };

    home-manager.users."${config.my.username}" = {
      xdg = {
        enable = true;
        inherit (xdgHomes)
          cacheHome
          configHome
          dataHome
          stateHome
          ;
        # GUI apps (e.g. Hammerspoon) inherit neither shell env vars nor a
        # reliable machine name (an MDM may rename it), so publish the logical
        # host name as a file they can read.
        dataFile."host-name".text = config.my.hostName;
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
