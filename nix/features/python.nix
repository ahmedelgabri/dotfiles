{inputs, ...}: let
  # The actual NixOS module for python configuration
  pythonModule = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.python;
  in {
    options = with lib; {
      my.modules.python = {
        enable = mkEnableOption ''
          Whether to enable python module
        '';
      };
    };

    config = with lib;
      mkIf cfg.enable {
        my = {
          env = {PYTHONSTARTUP = "$XDG_CONFIG_HOME/python/.pythonrc.py";};

          user = {
            packages = with pkgs; [
              (python3.withPackages (ps:
                with ps; [
                  pip
                  setuptools
                  pynvim
                  vobject # Mutt calendar script
                ]))
              # nixos.python38Packages.httpx
              ruff
              basedpyright
              uv
              ty
            ];
          };

          hm.file = {
            ".config/python" = {
              recursive = true;
              source = ../../config/python;
            };
            ".config/pip" = {
              recursive = true;
              source = ../../config/pip;
            };
          };
        };
      };
  };
in {
  # Define modules for both darwin and nixos to import
  flake.modules.darwin.python = pythonModule;
  flake.modules.nixos.python = pythonModule;
}
