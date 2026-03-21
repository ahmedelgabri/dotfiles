let
  module = {config, ...}: let
    inherit (config.my.user) home;
    inherit (config.home-manager.users."${config.my.username}") xdg;
  in {
    config = {
      homebrew.casks = [
        "karabiner-elements"
      ];

      # Karabiner mutates its config from the GUI, so keep this as a live
      # symlink instead of deploying it as an immutable Home Manager file.
      system.activationScripts.postActivation.text =
        /*
        bash
        */
        ''
          echo ":: -> Running karabiner activationScript..."

          # Handle mutable configs
          echo "Linking karabiner folders..."
          ln -sf ${home}/.dotfiles/config/karabiner ${xdg.configHome}
        '';
    };
  };
in {
  flake.modules.darwin.karabiner = module;
}
