let
  module =
    { config, ... }:
    let
      inherit (config.my.user) home;
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
              config.lib.file.mkOutOfStoreSymlink "${home}/.dotfiles/config/.hammerspoon";
          };
      };
    };
in
{
  flake.modules.darwin.hammerspoon = module;
}
