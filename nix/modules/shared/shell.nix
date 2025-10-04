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
  inherit (config.my) hm devFolder hostConfigHome company;
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
        environment = {
          shellAliases = {
            emptytrash = "sudo rm -rfv /Volumes/*/.Trashes;sudo rm -rfv ~/.Trash";
            flushdns = "sudo killall -HUP mDNSResponder";
          };

          variables = {
            LANG = "en_US.UTF-8";
            LC_TIME = "en_GB.UTF-8";
            NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
            # NOTE: Darwin doesn't set them by default, unlike NixOS. So we have to set them.
            # This is just using what's inside home-manager. Defaults are here
            # https://github.com/nix-community/home-manager/blob/a4b0a3faa4055521f2a20cfafe26eb85e6954751/modules/misc/xdg.nix#L14-L17
            XDG_CACHE_HOME = hm.cacheHome;
            XDG_CONFIG_HOME = hm.configHome;
            XDG_DATA_HOME = hm.dataHome;
            XDG_STATE_HOME = hm.stateHome;
          };

          systemPackages = with pkgs;
            [
              openssl
              gawk
              gnused
              coreutils
              findutils
              (pkgs.writeScriptBin "nixsw"
                /*
                bash
                */
                ''
                  pushd $DOTFILES/
                  sudo darwin-rebuild switch --flake .
                  popd
                '')
            ]
            ++
            # Packages broken on Intel
            (
              lib.optional (stdenv.hostPlatform.system == "aarch64-darwin")
              lnav # System Log file navigator
            );
        };
      })

      (mkIf isLinux {
        environment = {
          systemPackages = with pkgs; [dwm dmenu xclip];

          shellAliases = {
            chmod = "chmod --preserve-root -v";
            chown = "chown --preserve-root -v";
          };
        };
      })

      {
        environment = {
          shells = [pkgs.bashInteractive pkgs.zsh];
          shellAliases = {
            cp = "cp -iv";
            ln = "ln -iv";
            mv = "mv -iv";
            rm = "rm -i";
            mkdir = "mkdir -p";
            sudo = "sudo ";
            type = "type -a";
            c = "clear";
            df = "df -kh";
            du = "du -kh";
            fd = "fd --hidden";
            history-stat = ''fc -l 1 | awk '{print \$2}' | sort | uniq -c | sort -n -r | head'';
            history = "fc -il 1";
            jobs = "jobs -l";
            play = "mx ϟ";
            y = "yarn";
            p = "pnpm";
            b = "bun";
            top = "htop";
            l = "eza --all --long --color-scale=all --group-directories-first --sort=type --hyperlink --icons=auto --octal-permissions";
            ll = "eza --icons --tree --group-directories-first --all --level=2";
            lt = "eza --tree --group-directories-first --all";
            cat = "bat";
            grep = "grep --color=auto";
            get = "wget --continue --progress=bar --timestamping";
          };

          variables =
            # ====================================================
            # This list gets set in alphabetical order.
            # So care needs to be taken if two env vars depend on each other
            #
            # Allowed variables is only $HOME
            # Everything else has to be explicit
            # ====================================================
            rec {
              ADBLOCK = "true";
              AWS_CONFIG_FILE = "${hm.configHome}/aws/config";
              AWS_SHARED_CREDENTIALS_FILE = "${hm.configHome}/aws/credentials";
              BROWSER =
                if pkgs.stdenv.isDarwin
                then "open"
                else "xdg-open";
              CDPATH = ".:~:~/${devFolder}";
              COLORTERM = "truecolor";
              COMPANY = company;
              DOCKER_CONFIG = "${hm.configHome}/docker";
              DOTFILES = "$HOME/.dotfiles";
              DO_NOT_TRACK = "1"; # Future proof? https://consoledonottrack.com/
              ELINKS_CONFDIR = "${hm.configHome}/elinks";
              EZA_COLORS = "ur=35;nnn:gr=35;nnn:tr=35;nnn:uw=34;nnn:gw=34;nnn:tw=34;nnn:ux=36;nnn:ue=36;nnn:gx=36;nnn:tx=36;nnn:uu=36;nnn:uu=38;5;235:da=38;5;238";
              EZA_ICON_SPACING = "2";
              FZF_ALT_C_COMMAND = "${FZF_CTRL_T_COMMAND} --type d .";
              FZF_ALT_C_OPTS = "--preview='(${FZF_PREVIEW_COMMAND}) 2> /dev/null' --walker-skip .git,node_modules";
              FZF_CTRL_R_OPTS = "--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'";
              FZF_CTRL_T_COMMAND = "${lib.getExe pkgs.fd} --strip-cwd-prefix --hidden --follow --no-ignore-vcs";
              FZF_CTRL_T_OPTS = "--preview-window right:border-left:60%:hidden --preview='(${FZF_PREVIEW_COMMAND})' --walker-skip .git,node_modules";
              FZF_DEFAULT_COMMAND = "${FZF_CTRL_T_COMMAND} --type f";
              FZF_DEFAULT_OPTS = "--border thinblock --prompt='» ' --pointer='▶' --marker='✓ ' --reverse --tabstop 2 --multi --color=bg+:-1,marker:010 --separator='' --bind '?:toggle-preview' --info inline-right";
              # https://github.com/sharkdp/bat/issues/634#issuecomment-524525661
              FZF_PREVIEW_COMMAND = "COLORTERM=truecolor previewer {}";
              GATSBY_TELEMETRY_DISABLED = "1";
              GITHUB_USER = config.my.github_username;
              # https://github.blog/2022-04-12-git-security-vulnerability-announced/
              GIT_CEILING_DIRECTORIES = builtins.dirOf home;
              HOMEBREW_INSTALL_BADGE = "⚽️";
              HOMEBREW_NO_ANALYTICS = "1";
              HOST_CONFIGS = "${hostConfigHome}";
              KEYTIMEOUT = "1";
              KITTY_LISTEN_ON = "unix:/tmp/kitty";
              # Set the default Less options.
              # Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
              # Remove -X and -F (exit if the content fits on one screen) to enable it.
              LESS = "-F -g -i -M -R -S -w -X -z-4";
              # LESSOPEN = "|${lib.getExe pkgs.lesspipe}.sh %s";
              LS_COLORS = "$(${lib.getExe pkgs.vivid} generate ~/.config/vivid/theme.yml)";
              NEXT_TELEMETRY_DISABLED = "1";
              NOTES_DIR = "${PERSONAL_STORAGE}/notes";
              PAGER = "less";
              PERSONAL_STORAGE = "$HOME/Sync";
              PROJECTS = "$HOME/${devFolder}/personal/dev";
              RLWRAP_HOME = "${hm.dataHome}/rlwrap";
              # Better spell checking & auto correction prompt
              SHELL = "${pkgs.zsh}/bin/zsh";
              SPROMPT = "zsh: correct %F{red}'%R'%f to %F{blue}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]?";
              VIM_FZF_LOG = ''"$(${lib.getExe pkgs.git} config --get alias.l 2>/dev/null | awk '{$1=""; print $0;}' | tr -d '\r')"'';
              ZCOMPDUMP_PATH = "${ZDOTDIR}/.zcompdump";
              ZDOTDIR = "${hm.configHome}/zsh";
              # I use a single zk notes dir, so set it and forget
              ZK_NOTEBOOK_DIR = "${NOTES_DIR}";
              WORK = "$HOME/${devFolder}/work";
              _ZO_DATA_DIR = "${hm.configHome}/zoxide";
              CARAPACE_BRIDGES = "zsh,bash,fish,inshellisense";
            };

          systemPackages = with pkgs; [
            ast-grep
            cachix
            curl
            direnv
            fzf
            grc
            htop
            hyperfine
            jq
            pass
            ncdu
            nix-direnv
            pandoc
            ripgrep
            rsync
            wget
            zoxide
            zsh-powerlevel10k
            (pkgs.writeScriptBin "nixup"
              /*
              bash
              */
              ''
                pushd $DOTFILES/
                nix flake update
                popd
              '')
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
              eza
              fd
              ffmpeg
              glow
              gum # https://github.com/charmbracelet/gum
              hcron
              mods # https://github.com/charmbracelet/mods
              scc
              shellcheck
              shfmt # Doesn't work with zsh, only sh & bash
              presenterm # CLI markdown presentation tool
              tokei
              vivid
              zsh-autosuggestions
              carapace
              zsh-fast-syntax-highlighting
              (imagemagick.override {
                ghostscriptSupport = true;
              })
              mermaid-cli
              ghostscript # to preview PDFs as images
              poppler_utils # to preview PDFs as text
              newsraft
              bun
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
        };

        system.activationScripts.postActivation.text = ''
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
            (
              [
                /*
                zsh
                */
                ''
                  export LESS_TERMCAP_mb=$'\E[1;31m'   # Begins blinking.
                  export LESS_TERMCAP_md=$'\E[1;31m'   # Begins bold.
                  export LESS_TERMCAP_me=$'\E[0m'      # Ends mode.
                  export LESS_TERMCAP_se=$'\E[0m'      # Ends standout-mode.
                  export LESS_TERMCAP_so=$'\E[7m'      # Begins standout-mode.
                  export LESS_TERMCAP_ue=$'\E[0m'      # Ends underline.
                  export LESS_TERMCAP_us=$'\E[1;32m'   # Begins underline.
                  # Remove path separator from WORDCHARS.
                  WORDCHARS=${"$"}{WORDCHARS//[\/]}
                ''
              ]
              ++ (map builtins.readFile [
                ../../../config/zsh.d/.zshenv
              ])
            );

          # zshrc
          interactiveShellInit =
            lib.concatStringsSep "\n"
            ([
                /*
                zsh
                */
                ''

                  ##############################################################
                  # Profiling.
                  ##############################################################

                  # Start profiling (uncomment when necessary)
                  #
                  # See: https://stackoverflow.com/a/4351664/2103996

                  # Per-command profiling:

                  # zmodload zsh/datetime
                  # setopt promptsubst
                  # PS4='+$EPOCHREALTIME %N:%i> '
                  # # More human readable
                  # PS4=$'%D{%S.%.} %N:%i> '
                  # exec 3>&2 2> startlog.$$
                  # setopt xtrace prompt_subst

                  # Per-function profiling:

                  # zmodload zsh/zprof

                  # Enable instant prompt
                  if [[ -r "${"$"}{XDG_CACHE_HOME:-${"$"}HOME/.cache}/p10k-instant-prompt-${"$"}{(%):-%n}.zsh" ]]; then
                    source "${"$"}{XDG_CACHE_HOME:-${"$"}HOME/.cache}/p10k-instant-prompt-${"$"}{(%):-%n}.zsh"
                  fi

                  # Must be here because nix-darwin defaults are set in zshrc https://github.com/LnL7/nix-darwin/blob/bd7d1e3912d40f799c5c0f7e5820ec950f1e0b3d/modules/programs/zsh/default.nix#L174-L177
                  export HISTFILE="${"$"}{ZDOTDIR}/.zsh_history"
                  export HISTSIZE=10000000
                  export SAVEHIST=${"$"}HISTSIZE
                  export HISTFILESIZE=${"$"}HISTSIZE

                  autoload -U select-word-style
                  # only alphanumeric chars are considered WORDCHARS
                  select-word-style bash

                  autoload -Uz compinit && compinit -C -d "${"$"}ZCOMPDUMP_PATH"

                  # Autocomplete the g script
                  if (( ${"$"}+commands[hub] )); then
                    compdef g=hub
                  elif (( ${"$"}+commands[git] )); then
                    compdef g=git
                  fi

                  # For speed:
                  # https://github.com/zsh-users/zsh-autosuggestions#disabling-automatic-widget-re-binding
                  ZSH_AUTOSUGGEST_MANUAL_REBIND=1
                  ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd history completion)
                ''
              ]
              ++ map builtins.readFile [
                ../../../config/zsh.d/zsh/config/options.zsh
                ../../../config/zsh.d/zsh/config/input.zsh
                ../../../config/zsh.d/zsh/config/completion.zsh
                "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
              ]
              ++ [
                /*
                zsh
                */
                ''
                  # I have to source this file instead of reading it because it depends on reading files in its own directory
                  # https://github.com/zdharma-continuum/fast-syntax-highlighting/blob/cf318e06a9b7c9f2219d78f41b46fa6e06011fd9/fast-syntax-highlighting.plugin.zsh#L339-L340
                  source "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh"

                  # Very slow chormas https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/27
                  unset "FAST_HIGHLIGHT[chroma-whatis]" "FAST_HIGHLIGHT[chroma-man]"

                  # This breaks p10k instant prompt if I inline the file, but sourcing works fine
                  source "${pkgs.grc}/etc/grc.zsh"

                  source <(${lib.getExe pkgs.fzf} --zsh)

                  eval "${"$"}(${lib.getExe pkgs.direnv} hook zsh)"
                  eval "${"$"}(${lib.getExe pkgs.atuin} init zsh --disable-up-arrow --disable-ctrl-r)"
                  eval "${"$"}(${lib.getExe pkgs.zoxide} init zsh --hook pwd)"

                  source <(carapace _carapace)
                ''
                (builtins.readFile ../../../config/zsh.d/zsh/config/extras.zsh)
                (builtins.readFile ../../../config/zsh.d/.p10k.zsh)
                ''
                  # Per machine config
                  if [ -f ${"$"}HOST_CONFIGS/zshrc ]; then
                  	source ${"$"}HOST_CONFIGS/zshrc
                  fi
                  #
                  # End profiling (uncomment when necessary)
                  #

                  # Per-command profiling:

                  # unsetopt xtrace
                  # exec 2>&3 3>&-

                  # Per-function profiling:

                  # zprof
                ''
              ]);

          promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        };
      }
    ]);
}
