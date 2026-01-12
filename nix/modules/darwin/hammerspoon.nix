# Hammerspoon module
{...}: {
  flake.darwinModules.hammerspoon = {config, ...}: let
    inherit (config.my.user) home;
  in {
    homebrew.casks = [
      "hammerspoon"
    ];

    system.activationScripts.postActivation.text =
      /*
      bash
      */
      ''
        echo ":: -> Running hammerspoon activationScript..."

        # Handle mutable configs
        echo "Linking hammerspoon folders..."
        ln -sf ${home}/.dotfiles/config/.hammerspoon ${home}
      '';
  };
}
