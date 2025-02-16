{
  lib,
  config,
  ...
}: let
  inherit (config.my.user) home;
  inherit (config.my) hm;
  cfg = config.my.modules.karabiner;
in {
  options = with lib; {
    my.modules.karabiner = {
      enable = mkEnableOption ''
        Whether to enable karabiner module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      homebrew.casks = [
        "karabiner-elements"
      ];

      # my.hm.file = {
      #   ".config/karabiner/karabiner.json" = {
      #     source = ../../../config/karabiner/karabiner.json;
      #   };
      # };

      # The config should be "live" because it can be modified from the app GUI
      # At least for now and until I reach a stable state, I'd like to symlink it instead
      system.activationScripts.postUserActivation.text =
        /*
        bash
        */
        ''
          echo ":: -> Running karabiner activationScript..."

          # Handle mutable configs
          echo "Linking karabiner folders..."
          ln -sf ${home}/.dotfiles/config/karabiner ${hm.configHome}
        '';
    };
}
