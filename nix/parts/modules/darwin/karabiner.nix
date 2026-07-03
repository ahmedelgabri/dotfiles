let
  module =
    { config, ... }:
    let
      inherit (config.my.user) home;
    in
    {
      config = {
        homebrew.casks = [
          "karabiner-elements"
        ];

        # Karabiner mutates its config from the GUI, so keep this as a live
        # symlink instead of deploying it as an immutable Home Manager file.
        home-manager.users."${config.my.username}" =
          { config, ... }:
          {
            xdg.configFile."karabiner".source =
              config.lib.file.mkOutOfStoreSymlink "${home}/.dotfiles/config/karabiner";
          };
      };
    };
in
{
  flake.modules.darwin.karabiner = module;
}
