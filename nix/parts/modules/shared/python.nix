let
  module = {
    generic = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        my.env.PYTHONSTARTUP = "$XDG_CONFIG_HOME/python/.pythonrc.py";

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
