{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.my.modules.yazi;
in {
  options = with lib; {
    my.modules.yazi = {
      enable = mkEnableOption ''
        Whether to enable yazi module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.user = {
        packages = with pkgs; [
          yazi
          zoxide
          fzf
          fd
          ripgrep
          # https://yazi-rs.github.io/docs/quick-start#shell-wrapper
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

      my.hm.file = {
        ".config/yazi" = {
          recursive = true;
          source = ../../../config/yazi;
        };

        ".config/yazi/plugins/smart-enter.yazi" = {
          recursive = true;
          source = "${inputs.yazi-plugins}/smart-enter.yazi";
        };

        ".config/yazi/plugins/toggle-pane.yazi" = {
          recursive = true;
          source = "${inputs.yazi-plugins}/toggle-pane.yazi";
        };

        ".config/yazi/plugins/full-border.yazi" = {
          recursive = true;
          source = "${inputs.yazi-plugins}/full-border.yazi";
        };

        ".config/yazi/plugins/git.yazi" = {
          recursive = true;
          source = "${inputs.yazi-plugins}/git.yazi";
        };

        ".config/yazi/plugins/glow.yazi/main.lua" = {
          recursive = true;
          source = "${inputs.yazi-glow}/init.lua";
        };
      };
    };
}
