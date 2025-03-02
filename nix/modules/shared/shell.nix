# This is handcrafted setup to keep the same performance characteristics I had
# before using nix or even improve it. Simple rules followed here are:
#
# - Setup things as early as possible when the shell runs
# - Inline files when possible instead of souring then
# - User specific shell files are to override or for machine specific setup
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.my.modules.shell;
  inherit (config.my.user) home;
  inherit (config.my) hm devFolder hostConfigHome;
  inherit (pkgs.stdenv) isDarwin isLinux;

  local_zshrc = "${hostConfigHome}/zshrc";
in {
  options = with lib; {
    my.modules.shell = {
      enable = mkEnableOption ''
        Whether to enable shell module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (mkIf isDarwin {
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
      })

      (mkIf isLinux {
        # systemd
      })

      {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment = {
          shells = [pkgs.bashInteractive pkgs.zsh];
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
          };

          systemPackages = with pkgs;
            (
              if stdenv.isDarwin
              then [openssl gawk gnused coreutils findutils]
              else [dwm dmenu xclip]
            )
            ++
            # Packages broken on Intel
            (
              lib.optional (stdenv.hostPlatform.system == "aarch64-darwin")
              lnav # System Log file navigator
            )
            ++ [
              ast-grep
              cachix
              curl
              direnv
              fzf
              grc
              htop
              hyperfine
              jq
              # ncdu
              nix-direnv
              pandoc
              ripgrep
              rsync
              wget
              zoxide
              zsh-powerlevel10k
            ];
        };

        my = {
          user = {
            shell = pkgs.zsh;
            packages = with pkgs; [
              _1password-cli
              atuin
              bat
              # buku
              difftastic
              eza
              fd
              ffmpeg
              glow
              gum # https://github.com/charmbracelet/gum
              hcron
              mods # https://github.com/charmbracelet/mods
              rename
              scc
              shellcheck
              shfmt # Doesn't work with zsh, only sh & bash
              slides # CLI markdown presentation tool
              tealdeer # rust implementation of `tldr`
              tokei
              vivid
              zsh-autosuggestions
              zsh-completions
              zsh-fast-syntax-highlighting
              zsh-history-substring-search
              (imagemagick.override {
                ghostscriptSupport = true;
              })
              mermaid-cli
              ghostscript # to preview PDFs as images
              poppler_utils # to preview PDFs as text
              aider-chat
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
              text =
                lib.concatStringsSep "\n"
                [
                  "source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc"
                  (builtins.readFile ../../../config/direnv/direnvrc)
                ];
            };
            # This is an emptyfile that's needed to get rid of the "Last login..." message when opening a new shell
            ".hushlogin" = {
              text = "";
            };
            ".config/vivid" = {
              recursive = true;
              source = ../../../config/vivid;
            };
            ".config/atuin" = {
              source = ../../../config/atuin;
            };
          };

          env =
            # ====================================================
            # This list gets set in alphabetical order.
            # So care needs to be taken if two env vars depend on each other
            # ====================================================
            rec {
              BROWSER =
                if pkgs.stdenv.isDarwin
                then "open"
                else "xdg-open";
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
              FZF_ALT_C_OPTS = "--preview='(${FZF_PREVIEW_COMMAND}) 2> /dev/null'";
              CDPATH = ".:~:~/${devFolder}";
              PROJECTS = "$HOME/${devFolder}/personal/dev";
              WORK = "$HOME/${devFolder}/work";
            };
        };

        system.activationScripts.postUserActivation.text = ''
          echo ":: -> Running shell activationScript..."
          if [ ! -e "${local_zshrc}" ]; then
          	mkdir -p "$(dirname "${local_zshrc}")"

            cat > ${local_zshrc}<< EOF
          	# vim:ft=zsh:
          	[[ -z "$GITHUB_TOKEN" ]] && echo "⚠ GITHUB_TOKEN is not set"
          	[[ -z "$HOMEBREW_GITHUB_API_TOKEN" ]] && echo "⚠ HOMEBREW_GITHUB_API_TOKEN is not set"
          	[[ -z "$WEECHAT_PASSPHRASE" ]] && echo "⚠ WEECHAT_PASSPHRASE is not set"
          	[[ -z "$NPM_REGISTRY_TOKEN" ]] && echo "⚠ NPM_REGISTRY_TOKEN is not set"
          	[[ -z "$GITHUB_REGISTRY_TOKEN" ]] && echo "⚠ GITHUB_REGISTRY_TOKEN is not set"
          	[[ -z "$GH_PASS" ]] && echo "⚠ GH_PASS is not set"
          EOF
          fi

          if dscl . -read /Users/${config.my.username} UserShell | grep -qv "/run/current-system/sw/bin/zsh"; then
            echo ":: -> Changing Shell..."
            sudo dscl . -create /Users/${config.my.username} UserShell /run/current-system/sw/bin/zsh
          fi
        '';

        programs.zsh = {
          enable = true;
          # This will also add nix-zsh-completions to the systemPackages.
          # https://github.com/LnL7/nix-darwin/blob/58b905ea87674592aa84c37873e6c07bc3807aba/modules/programs/zsh/default.nix#L117
          enableCompletion = true;
          # Default is the value of enableCompletion but I want to handle it myself
          # https://github.com/LnL7/nix-darwin/blob/58b905ea87674592aa84c37873e6c07bc3807aba/modules/programs/zsh/default.nix#L76
          enableGlobalCompInit = false;
          enableBashCompletion = false;

          # I use fast-syntax-highlighting instead of zsh-syntax-highlighting
          enableSyntaxHighlighting = false;

          ########################################################################
          # Instead of sourcing, I can read the files & save startiup time instead
          ########################################################################

          # zshenv
          shellInit =
            lib.concatStringsSep "\n"
            (map builtins.readFile [
                ../../../config/zsh.d/.zshenv
              ]
              ++ [
                /*
                zsh
                */
                "fpath+=(${pkgs.zsh-completions}/share/zsh/site-functions)"
              ]);

          # zshrc
          interactiveShellInit =
            lib.concatStringsSep "\n"
            ([
                /*
                zsh
                */
                ''
                  # Enable instant prompt
                  if [[ -r "${"$"}{XDG_CACHE_HOME:-${"$"}HOME/.cache}/p10k-instant-prompt-${"$"}{(%):-%n}.zsh" ]]; then
                    source "${"$"}{XDG_CACHE_HOME:-${"$"}HOME/.cache}/p10k-instant-prompt-${"$"}{(%):-%n}.zsh"
                  fi

                  # NOTE: must come before zsh-history-substring-search & zsh-syntax-highlighting.
                  autoload -U select-word-style
                  # only alphanumeric chars are considered WORDCHARS
                  select-word-style bash

                  autoload -Uz compinit && compinit -C -d "${"$"}ZCOMPDUMP_PATH"
                ''
              ]
              ++ map builtins.readFile [
                ../../../config/zsh.d/zsh/config/options.zsh
                ../../../config/zsh.d/zsh/config/input.zsh
                ../../../config/zsh.d/zsh/config/completion.zsh
                ../../../config/zsh.d/zsh/config/aliases.zsh
                "${pkgs.fzf}/share/fzf/completion.zsh"
                "${pkgs.fzf}/share/fzf/key-bindings.zsh"
                "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
                "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
              ]
              ++ [
                /*
                zsh
                */
                ''
                  # I have to source this file instead of reading it because it depends on reading files in its own directory
                  # https://github.com/zdharma-continuum/fast-syntax-highlighting/blob/cf318e06a9b7c9f2219d78f41b46fa6e06011fd9/fast-syntax-highlighting.plugin.zsh#L339-L340
                  #
                  # It must be sourced before history-substring-search https://github.com/zsh-users/zsh-history-substring-search?tab=readme-ov-file#usage
                  source "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh"

                  # Very slow chormas https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/27
                  unset "FAST_HIGHLIGHT[chroma-whatis]" "FAST_HIGHLIGHT[chroma-man]"

                  # bind UP and DOWN keys
                  bindkey '^[[A' history-substring-search-up
                  bindkey '^[[B' history-substring-search-down
                  # In vi mode
                  bindkey -M vicmd 'k' history-substring-search-up
                  bindkey -M vicmd 'j' history-substring-search-down

                  # Note that this will only ensure unique history if we supply a prefix
                  # before hitting "up" (ie. we perform a "search"). HIST_FIND_NO_DUPS
                  # won't prevent dupes from appearing when just hitting "up" without a
                  # prefix (ie. that's "zle up-line-or-history" and not classified as a
                  # "search"). So, we have HIST_IGNORE_DUPS to make life bearable for that
                  # case.
                  #
                  # https://superuser.com/a/1494647/322531
                  HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

                  # For speed:
                  # https://github.com/zsh-users/zsh-autosuggestions#disabling-automatic-widget-re-binding
                  ZSH_AUTOSUGGEST_MANUAL_REBIND=1
                  ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd history completion)

                  # This breaks p10k instant prompt if I inline the file, but sourcing works fine
                  source "${pkgs.grc}/etc/grc.zsh"
                ''
                (builtins.readFile ../../../config/zsh.d/.zshrc)
                (builtins.readFile ../../../config/zsh.d/.p10k.zsh)
              ]);

          promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        };
      }
    ]);
}
