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
            sourceRoot = "${myConfig.dotfilesDir}/config/jj";
            targetRoot = "jj";
          }
          // {
            "jj/conf.d/nix.toml".text = ''
              # ${myConfig.nix_managed}
              #:schema https://docs.jj-vcs.dev/latest/config-schema.json


              --when.hostnames = ["${myConfig.hostName}"]

              [user]
              ${optionalString (myConfig.email != "") "email = \"${myConfig.email}\""}

              [git]
              push-bookmark-prefix = '${myConfig.github_username}/'

              [remotes.origin]
              # https://docs.jj-vcs.dev/latest/config/#automatic-tracking-of-bookmarks
              auto-track-bookmarks = "${myConfig.github_username}/*"

              [templates]
              # Generate prefixed bookmark names when running `jj git push --change`:
              # See: https://jj-vcs.github.io/jj/latest/config/#generated-bookmark-names-on-push
              git_push_bookmark = '"${myConfig.github_username}/" ++ change_id.short()'

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
