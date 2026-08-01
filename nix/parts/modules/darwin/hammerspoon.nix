let
  module =
    { config, ... }:
    let
      inherit (config.my) dotfilesDir;
    in
    {
      config = {
        homebrew.casks = [
          "hammerspoon"
        ];

        # Link the config out of the store so it stays live-editable without
        # a rebuild.
        home-manager.users."${config.my.username}" =
          { config, ... }:
          {
            home.file.".hammerspoon".source =
              config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/.hammerspoon";
          };
      };
    };
in
{
  flake.modules.darwin.hammerspoon = module;
}
