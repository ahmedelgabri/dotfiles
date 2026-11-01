let
  module =
    { config, pkgs, ... }:
    let
      inherit (config.my) dotfilesDir;
    in
    {
      config = {
        # Leaving `config` empty makes the service read
        # ~/.config/sketchybar/sketchybarrc, linked below. The bar covers the
        # menu bar, which the darwin defaults already auto-hide.
        services.sketchybar = {
          enable = true;
          extraPackages = [ pkgs.jq ];
        };

        # Link the config out of the store so it stays live-editable without
        # a rebuild.
        home-manager.users."${config.my.username}" =
          { config, ... }:
          {
            xdg.configFile."sketchybar".source =
              config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/sketchybar";
          };
      };
    };
in
{
  flake.modules.darwin.sketchybar = module;
}
