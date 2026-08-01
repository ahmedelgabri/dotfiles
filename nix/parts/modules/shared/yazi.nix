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
          my.user.packages = with pkgs; [
            yazi
            zoxide
            fzf
            fd
            ripgrep
            (pkgs.writeShellScriptBin "yy" ''
              set -ue -o pipefail

              function ya() {
              	local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
              	yazi "$@" --cwd-file="$tmp"
              	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
              		cd -- "$cwd"
              	fi
              	rm -f -- "$tmp"
              }

              ya "$@"
            '')
          ];
        };
      };

    homeManager =
      { config, inputs, myConfig, ... }:
      {
        xdg.configFile =
          config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/yazi;
            sourceRoot = "${myConfig.dotfilesDir}/config/yazi";
            targetRoot = "yazi";
          }
          // {
            "yazi/plugins/smart-enter.yazi" = {
              recursive = true;
              source = "${inputs.yazi-plugins}/smart-enter.yazi";
            };

            "yazi/plugins/toggle-pane.yazi" = {
              recursive = true;
              source = "${inputs.yazi-plugins}/toggle-pane.yazi";
            };

            "yazi/plugins/full-border.yazi" = {
              recursive = true;
              source = "${inputs.yazi-plugins}/full-border.yazi";
            };

            "yazi/plugins/git.yazi" = {
              recursive = true;
              source = "${inputs.yazi-plugins}/git.yazi";
            };

            "yazi/plugins/types.yazi" = {
              recursive = true;
              source = "${inputs.yazi-plugins}/types.yazi";
            };

            "yazi/plugins/glow.yazi/main.lua" = {
              source = "${inputs.yazi-glow}/init.lua";
            };
          };
      };
  };
in
{
  flake = {
    modules = {
      generic.yazi = module.generic;
      homeManager.yazi = module.homeManager;
    };
  };
}
