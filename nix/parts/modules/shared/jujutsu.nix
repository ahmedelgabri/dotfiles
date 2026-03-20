let
  module = {
    generic = {
      pkgs,
      lib,
      config,
      ...
    }: {
      config = with lib; {
        environment.systemPackages = with pkgs; [
          jujutsu
        ];
      };
    };

    homeManager = {
      lib,
      myConfig,
      ...
    }:
      with lib; {
        xdg.configFile = {
          "jj" = {
            recursive = true;
            source = ../../../../config/jj;
          };

          "jj/conf.d/nix.toml".text = ''
            # ${myConfig.nix_managed}
            #:schema https://docs.jj-vcs.dev/latest/config-schema.json


            --when.hostnames = ["${myConfig.hostName}"]

            [user]
            ${optionalString (myConfig.name != "") "name = \"${myConfig.name}\""}
            ${optionalString (myConfig.email != "") "email = \"${myConfig.email}\""}

          '';
        };
      };
  };
in {
  flake = {
    modules = {
      generic.jujutsu = module.generic;
      homeManager.jujutsu = module.homeManager;
    };
  };
}
