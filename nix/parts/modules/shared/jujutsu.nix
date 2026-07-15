let
  module = {
    generic =
      {
        pkgs,
        lib,
        ...
      }:
      {
        config = with lib; {
          environment.systemPackages = with pkgs; [
            jujutsu
          ];
        };
      };

    homeManager =
      {
        config,
        lib,
        myConfig,
        ...
      }:
      with lib;
      {
        xdg.configFile =
          config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/jj;
            sourceRoot = "${config.home.homeDirectory}/.dotfiles/config/jj";
            targetRoot = "jj";
          }
          // {
            "jj/conf.d/nix.toml".text = ''
              # ${myConfig.nix_managed}
              #:schema https://docs.jj-vcs.dev/latest/config-schema.json


              --when.hostnames = ["${myConfig.hostName}"]

              [user]
              ${optionalString (myConfig.email != "") "email = \"${myConfig.email}\""}

            '';
          };
      };
  };
in
{
  flake = {
    modules = {
      generic.jujutsu = module.generic;
      homeManager.jujutsu = module.homeManager;
    };
  };
}
