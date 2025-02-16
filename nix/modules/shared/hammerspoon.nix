{
  lib,
  config,
  ...
}: let
  inherit (config.my.user) home;
  cfg = config.my.modules.hammerspoon;
in {
  options = with lib; {
    my.modules.hammerspoon = {
      enable = mkEnableOption ''
        Whether to enable hammerspoon module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      homebrew.casks = [
        "hammerspoon"
      ];

      system.activationScripts.postUserActivation.text =
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
