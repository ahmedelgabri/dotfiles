let
  module = {
    generic = {
      pkgs,
      lib,
      config,
      ...
    }: let
      inherit (config.home-manager.users."${config.my.username}") xdg;
    in {
      config = with lib; {
        environment.variables.PYTHONSTARTUP = "${xdg.configHome}/python/.pythonrc.py";

        my.user.packages = with pkgs; [
          (python3.withPackages (ps:
            with ps; [
              pip
              setuptools
              pynvim
            ]))
          ruff
          basedpyright
          uv
          ty
        ];
      };
    };

    homeManager = _: {
      xdg.configFile = {
        "python" = {
          recursive = true;
          source = ../../../../config/python;
        };
        "pip" = {
          recursive = true;
          source = ../../../../config/pip;
        };
        "uv" = {
          recursive = true;
          source = ../../../../config/uv;
        };
      };
    };
  };
in {
  flake = {
    modules = {
      generic.python = module.generic;
      homeManager.python = module.homeManager;
    };
  };
}
