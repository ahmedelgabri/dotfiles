{
  pkgs,
  lib,
  config,
  ...
}: let
  homeDir = config.my.user.home;
  cfg = config.my.modules.ai;
  inherit (pkgs.stdenv) isDarwin isLinux;
in {
  options = with lib; {
    my.modules.ai = {
      enable = mkEnableOption ''
        Whether to enable ai module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (mkIf isDarwin {
        launchd.daemons.ollama = {
          command = "${pkgs.ollama}/bin/ollama serve";
          serviceConfig = {
            Label = "ollama";
            UserName = config.my.username;
            GroupName = "staff";
            ExitTimeOut = 30;
            Disabled = false;
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "${homeDir}/Library/Logs/ollama-output.log";
            StandardErrorPath = "${homeDir}/Library/Logs/ollama-error.log";
            EnvironmentVariables = {
              "OLLAMA_HOST" = "0.0.0.0:11434";
            };
          };
        };
        homebrew.casks = [
          "msty"
          "claude"
        ];
      })
      (mkIf isLinux {
        my.user = {
          packages = with pkgs; [
            open-webui
          ];
        };
      })

      {
        environment = {
          shellAliases = {
            aider = "${pkgs.aider-chat}/bin/aider --config ~/.dotfiles/config/aider/config.yml";
          };
        };
        my = {
          user = {
            packages = with pkgs; [
              ollama
              llama-cpp
              llm
              codex
              claude-code
              aider-chat
            ];
          };
          hm.file = {
            ".claude/CLAUDE.md" = {
              source = ../../../config/claude/CLAUDE.md;
            };
          };
        };
      }
    ]);
}
