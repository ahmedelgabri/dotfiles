{inputs, ...}: let
  pythonModule = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = {
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
  flake.modules.darwin.python = pythonModule;
  flake.modules.nixos.python = pythonModule;
}
