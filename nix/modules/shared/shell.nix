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
  inherit (config.my) hm;
  inherit (config.my) hostConfigHome;

  local_zshrc = "${hostConfigHome}/zshrc";
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
          # doesn't do what you think...
          # https://github.com/LnL7/nix-darwin/issues/779#issuecomment-1720066939
          loginShell = "${pkgs.zsh}/bin/zsh -l";
          shells = [ pkgs.bashInteractive pkgs.zsh ];
          variables = {
            LANG = "en_US.UTF-8";
            LC_TIME = "en_GB.UTF-8";
            # NOTE: Darwin doesn't set them by default, unlike NixOS. So we have to set them.
            # This is just using what's inside home-manager. Defaults are here
            # https://github.com/nix-community/home-manager/blob/a4b0a3faa4055521f2a20cfafe26eb85e6954751/modules/misc/xdg.nix#L14-L17
            XDG_CACHE_HOME = hm.cacheHome;
            XDG_CONFIG_HOME = hm.configHome;
            XDG_DATA_HOME = hm.dataHome;
            XDG_STATE_HOME = hm.stateHome;
            HOST_CONFIGS = "${hostConfigHome}";
            # https://github.blog/2022-04-12-git-security-vulnerability-announced/
            GIT_CEILING_DIRECTORIES = builtins.dirOf home;
            SHELL = "${pkgs.zsh}/bin/zsh";
            CDPATH = ".:~:~/Sites";
          };
          systemPackages = with pkgs;
            (if stdenv.isDarwin then [ openssl gawk gnused coreutils findutils ] else [ dwm dmenu xclip ]) ++ [
              curl
              wget
              cachix
              htop
              fzf
              direnv
              nix-direnv
              zsh
              zoxide
              rsync
            ];
        };

        my = {
          user = {
            shell = if pkgs.stdenv.isDarwin then [ pkgs.zsh ] else pkgs.zsh;
            packages = with pkgs; [
              tealdeer # rust implementation of `tldr`
              ncdu
              bat
              fd
              ripgrep
              vivid
              hyperfine
              jq
              grc
              zsh-powerlevel10k
              eza
              shellcheck
              shfmt # Doesn't work with zsh, only sh & bash
              lnav # System Log file navigator
              pandoc
              scc
              tokei
              _1password # CLI
              rename
              # buku
              difftastic
              ffmpeg
              slides # CLI markdown presentation tool
              # emanote # Only aarch64-darwin
              ast-grep
              glow
              gum # https://github.com/charmbracelet/gum
              mods # https://github.com/charmbracelet/mods
              hcron
            ];
          };

          hm.file = {
            ".config/zsh" = {
              recursive = true;
              source = ../../../config/zsh.d/zsh;
            };
            ".config/mods" = {
              recursive = true;
              source = ../../../config/mods;
            };
            ".terminfo" = {
              recursive = true;
              source = ../../../config/.terminfo;
            };
            ".config/direnv/direnvrc" = {
              text = lib.concatStringsSep "\n"
                [
                  "source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc"
                  (builtins.readFile ../../../config/direnv/direnvrc)
                ];
            };
            # This is an emptyfile that's needed to get rid of the "Last login..." message when opening a new shell
            ".hushlogin" = {
              text = "";
            };
          };

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
              FZF_PREVIEW_COMMAND = "COLORTERM=truecolor previewer {}";
              FZF_CTRL_T_COMMAND = "${pkgs.fd}/bin/fd --strip-cwd-prefix --hidden --follow --no-ignore-vcs";
              FZF_ALT_C_COMMAND = "${FZF_CTRL_T_COMMAND} --type d .";
              FZF_DEFAULT_OPTS = "--border --prompt='» ' --pointer='▶' --marker='✓ ' --reverse --tabstop 2 --multi --color=bg+:-1,marker:010 --separator='' --bind '?:toggle-preview'";
              FZF_CTRL_T_OPTS = "--preview-window right:border-left:60% --preview='(${FZF_PREVIEW_COMMAND})'";
              FZF_CTRL_R_OPTS = "--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'";
              FZF_ALT_C_OPTS = "--preview '(${pkgs.eza}/bin/eza --tree --group-directories-first {} || ${pkgs.tree}/bin/tree -C {}) 2> /dev/null'";
            };
        };

        # TODO: look at this later, because it's ugly
        system.activationScripts.postUserActivation.text = ''
          echo ":: -> Running shell activationScript..."
          # Creating needed folders

          if [ ! -e "${local_zshrc}" ]; then
          	mkdir -p $(dirname "${local_zshrc}")
          	echo '# vim:ft=zsh:' > ${local_zshrc}
          	echo '[[ -z "$GITHUB_TOKEN" ]] && echo "⚠ GITHUB_TOKEN is not set"' >> ${local_zshrc}
          	echo '[[ -z "$HOMEBREW_GITHUB_API_TOKEN" ]] && echo "⚠ HOMEBREW_GITHUB_API_TOKEN is not set"' >> ${local_zshrc}
          	echo '[[ -z "$WEECHAT_PASSPHRASE" ]] && echo "⚠ WEECHAT_PASSPHRASE is not set"' >> ${local_zshrc}
          	echo '[[ -z "$NPM_REGISTRY_TOKEN" ]] && echo "⚠ NPM_REGISTRY_TOKEN is not set"' >> ${local_zshrc}
          	echo '[[ -z "$GITHUB_REGISTRY_TOKEN" ]] && echo "⚠ GITHUB_REGISTRY_TOKEN is not set"' >> ${local_zshrc}
          	echo '[[ -z "$GH_PASS" ]] && echo "⚠ GH_PASS is not set"' >> ${local_zshrc}
          fi

          echo ":: -> Changing Shell..."
          # @TODO: wrap it in an if
          sudo dscl . -create /Users/${config.my.username} UserShell /run/current-system/sw/bin/zsh
        '';

        programs.zsh = {
          enable = true;
          # This will also add nix-zsh-completions to the systemPackages.
          # https://github.com/LnL7/nix-darwin/blob/58b905ea87674592aa84c37873e6c07bc3807aba/modules/programs/zsh/default.nix#L117
          enableCompletion = true;
          # Default is the value of enableCompletion but I want to handle it myself
          # https://github.com/LnL7/nix-darwin/blob/58b905ea87674592aa84c37873e6c07bc3807aba/modules/programs/zsh/default.nix#L76
          enableGlobalCompInit = false;

          ########################################################################
          # Instead of sourcing, I can read the files & save startiup time instead
          ########################################################################

          # zshenv
          shellInit = lib.concatStringsSep "\n"
            (map builtins.readFile [
              ../../../config/zsh.d/.zshenv
            ]);


          # zshrc
          interactiveShellInit = lib.concatStringsSep "\n"
            [
              ''
                if [[ -r "$${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$${(%):-%n}.zsh" ]]; then
                  source "$${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$${(%):-%n}.zsh"
                fi
              ''
              (lib.concatStringsSep "\n"
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
                ]))
              (builtins.readFile ../../../config/zsh.d/.p10k.zsh)
            ];


          promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        };
      }
    ]);
}
