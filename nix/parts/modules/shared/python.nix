let
  module = {
    generic =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      let
        inherit (config.home-manager.users."${config.my.username}") xdg;
      in
      {
        config = with lib; {
          environment.variables.PYTHONSTARTUP = "${xdg.configHome}/python/.pythonrc.py";

          my.user.packages = with pkgs; [
            (python3.withPackages (
              ps: with ps; [
                pip
                setuptools
                pynvim
              ]
            ))
            ruff
            basedpyright
            uv
            ty
          ];
        };
      };

    homeManager =
      { config, ... }:
      let
        dotfilesConfig = "${config.home.homeDirectory}/.dotfiles/config";
      in
      {
        xdg.configFile =
          config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/python;
            sourceRoot = "${dotfilesConfig}/python";
            targetRoot = "python";
          }
          // config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/pip;
            sourceRoot = "${dotfilesConfig}/pip";
            targetRoot = "pip";
          }
          // config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/uv;
            sourceRoot = "${dotfilesConfig}/uv";
            targetRoot = "uv";
          };
      };
  };
in
{
  flake = {
    modules = {
      generic.python = module.generic;
      homeManager.python = module.homeManager;
    };
  };
}
