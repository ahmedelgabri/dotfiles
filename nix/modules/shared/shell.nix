# This is handcrafted setup to keep the same performance characteristics I had
# before using nix or even improve it. Simple rules followed here are:
#
# - Setup things as early as possible when the shell runs
# - Inline files when possible instead of souring then
# - User specific shell files are to override or for machine specific setup

{ pkgs, lib, config, options, ... }:

let

  cfg = config.my.modules.shell;
  inherit (config.my.user) home;

  local_zshrc = "${home}/.zshrc.local";

  darwinPackages = with pkgs; [ openssl gawk gnused coreutils findutils ];
  nixosPackages = with pkgs; [ dwm dmenu xclip ];
in
{
  options = with lib; {
    my.modules.shell = {
      enable = mkEnableOption ''
        Whether to enable shell module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (if (builtins.hasAttr "launchd" options) then {
        launchd.user.agents."ui-mode-notify" = {
          serviceConfig = {
            ProgramArguments = [
              "${home}/.config/zsh/bin/ui-mode-notify"
              "${pkgs.zsh}/bin/zsh"
              "-c"
              "change-background"
            ];
            KeepAlive = true;
            StandardOutPath = "${home}/Library/Logs/ui-mode-notify-output.log";
            StandardErrorPath = "${home}/Library/Logs/ui-mode-notify-error.log";
          };
        };
      } else
        {
          # systemd
        })

      {

        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment = {
          shells = [ pkgs.bashInteractive_5 pkgs.zsh ];
          variables = {
            # NOTE: Darwin doesn't set them by default, unlike NixOS. So we have to set them.
            XDG_CACHE_HOME = "${home}/.cache";
            XDG_CONFIG_HOME = "${home}/.config";
            XDG_DATA_HOME = "${home}/.local/share";
          };
          systemPackages = with pkgs;
            (if stdenv.isDarwin then darwinPackages else nixosPackages) ++ [
              curl
              wget
              cachix
              htop
              fzf
              direnv
              nix-zsh-completions
              zsh
              zoxide
              rsync
            ];
        };

        my = {
          user = {
            shell = if pkgs.stdenv.isDarwin then [ pkgs.zsh ] else pkgs.zsh;
            packages = with pkgs; [
              bottom # fancy version of `top` with ASCII graphs
              tealdeer # rust implementation of `tldr`
              fzf
              ncdu
              bat
              jq
              fd
              grc
              pure-prompt
              hyperfine
              exa
              shellcheck
              shfmt # Doesn't work with zsh, only sh & bash
              lnav # System Log file navigator
              pandoc
              scc
              tokei
              _1password # CLI
              docker
              pass
              translate-shell
              rename
              glow
              # buku
              graph-easy
              graphviz
            ];
          };

          hm.file = with config.my;
            let

              glow_config = ''
                # ${nix_managed}
                # style name or JSON path (default "auto")
                style: "auto"
                # show local files only; no network (TUI-mode only)
                local: true
                # mouse support (TUI-mode only)
                mouse: false
                # use pager to display markdown
                pager: true
                # word-wrap at width
                width: 80'';
            in

            lib.mkMerge [
              (if pkgs.stdenv.isDarwin then {
                "Library/Preferences/glow/glow.yml".text = glow_config;
              } else
                {
                  ".config/glow/glow.yml".text = glow_config;
                })

              {
                ".config/zsh" = {
                  recursive = true;
                  source = ../../../config/zsh.d/zsh;
                };
                ".terminfo" = {
                  recursive = true;
                  source = ../../../config/.terminfo;
                };
              }
            ];

          env =
            # ====================================================
            # This list gets set in alphabetical order.
            # So care needs to be taken if two env vars depend on each other
            # ====================================================
            rec {
              BROWSER = if pkgs.stdenv.isDarwin then "open" else "xdg-open";
              GITHUB_USER = config.my.github_username;

              VIM_FZF_LOG = ''
                "$(${pkgs.git}/bin/git config --get alias.l 2>/dev/null | awk '{$1=""; print $0;}' | tr -d '\r')"'';

              FZF_DEFAULT_COMMAND = "${FZF_CTRL_T_COMMAND} --type f";
              # https://github.com/sharkdp/bat/issues/634#issuecomment-524525661
              FZF_PREVIEW_COMMAND =
                "COLORTERM=truecolor ${pkgs.bat}/bin/bat --style=changes --wrap never --color always {} || cat {} || (${pkgs.exa}/bin/exa --tree --group-directories-first {} || ${pkgs.tree}/bin/tree -C {})";
              FZF_CTRL_T_COMMAND =
                "${pkgs.fd}/bin/fd --hidden --follow --no-ignore-vcs";
              FZF_ALT_C_COMMAND = "${FZF_CTRL_T_COMMAND} --type d .";
              FZF_DEFAULT_OPTS =
                "--prompt='» ' --pointer='▶' --marker='✓ ' --reverse --tabstop 2 --multi --color=bg+:-1,marker:010 --bind '?:toggle-preview'";
              FZF_CTRL_T_OPTS =
                "--preview '(${FZF_PREVIEW_COMMAND}) 2> /dev/null' --preview-window down:60%:noborder";
              FZF_CTRL_R_OPTS =
                "--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'";
              FZF_ALT_C_OPTS =
                "--preview '(${pkgs.exa}/bin/exa --tree --group-directories-first {} || ${pkgs.tree}/bin/tree -C {}) 2> /dev/null'";
            };

        };

        # TODO: look at this later, because it's ugly
        system.activationScripts.postUserActivation.text = ''
          echo ":: -> Running shell activationScript..."
          # Creating needed folders

          if [ ! -e "${local_zshrc}" ]; then
            echo '# vim:ft=zsh:' > ${local_zshrc}
            echo '[[ -z "$GITHUB_TOKEN" ]] && echo "⚠ GITHUB_TOKEN is not set"' >> ${local_zshrc}
            echo '[[ -z "$HOMEBREW_GITHUB_API_TOKEN" ]] && echo "⚠ HOMEBREW_GITHUB_API_TOKEN is not set"' >> ${local_zshrc}
            echo '[[ -z "$WEECHAT_PASSPHRASE" ]] && echo "⚠ WEECHAT_PASSPHRASE is not set"' >> ${local_zshrc}
            echo '[[ -z "$NPM_REGISTRY_TOKEN" ]] && echo "⚠ NPM_REGISTRY_TOKEN is not set"' >> ${local_zshrc}
            echo '[[ -z "$GITHUB_REGISTRY_TOKEN" ]] && echo "⚠ GITHUB_REGISTRY_TOKEN is not set"' >> ${local_zshrc}
            echo '# Needed for grip & Markdown preview' >> ${local_zshrc}
            echo '[[ -z "$GH_PASS" ]] && echo "⚠ GH_PASS is not set"' >> ${local_zshrc}
            echo 'exit 1' >> ${local_zshrc}
          fi
        '';

        programs.zsh = {
          enable = true;
          enableCompletion = true;

          ########################################################################
          # Instead of sourcing, I can read the files & save startiup time instead
          ########################################################################

          # zshenv
          shellInit = lib.concatStringsSep "\n"
            (map builtins.readFile [
              "${pkgs.LS_COLORS.outPath}/lscolors.sh"
              ../../../config/zsh.d/.zshenv
            ]);


          # zshrc
          interactiveShellInit = lib.concatStringsSep "\n"
            (map builtins.readFile [
              ../../../config/zsh.d/zsh/config/options.zsh
              ../../../config/zsh.d/zsh/config/input.zsh
              ../../../config/zsh.d/zsh/config/completion.zsh
              ../../../config/zsh.d/zsh/config/utility.zsh
              ../../../config/zsh.d/zsh/config/aliases.zsh
              "${pkgs.grc}/etc/grc.zsh"
              "${pkgs.fzf}/share/fzf/completion.zsh"
              "${pkgs.fzf}/share/fzf/key-bindings.zsh"
              ../../../config/zsh.d/.zshrc
            ]);


          promptInit = "autoload -U promptinit; promptinit; prompt pure";
        };
      }
    ]);
}
