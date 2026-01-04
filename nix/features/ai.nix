{inputs, ...}: let
  # The actual NixOS module for ai configuration
  aiModule = {
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
            command = "${lib.getExe pkgs.ollama} serve";
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
            "claude"
          ];
        })
        (mkIf isLinux {
          })

        {
          environment = {
            # Claude.
            #
            # Make Claude execute MCP tools via token-friendly calls to `mcp-cli` instead of
            # loading thousands of tokens into context upfront for MCP tools you might not
            # actually use in the session:
            #
            # - https://gist.github.com/GGPrompts/50e82596b345557656df2fc8d2d54e2c
            # - https://github.com/anthropics/claude-code/issues/12836#issuecomment-3629052941
            #
            # To disable for a single session, do:
            #
            #     env -u ENABLE_EXPERIMENTAL_MCP_CLI ~/.claude/local/claude
            #
            # export ENABLE_EXPERIMENTAL_MCP_CLI=true

            # Alternatively, can use Advanced Tool Search:
            #
            # - https://github.com/anthropics/claude-code/issues/12836#issuecomment-3667047439
            #
            variables = {
              ENABLE_TOOL_SEARCH = true;
            };
          };

          my = {
            user = {
              packages = with pkgs; [
                ollama
                llama-cpp
                claude-code
                gemini-cli
                repomix
              ];
            };
            hm.file = {
              ".claude/CLAUDE.md" = {
                source = ../../config/claude/CLAUDE.md;
              };

              ".claude/agents" = {
                recursive = true;
                source = ../../config/claude/agents;
              };

              ".claude/docs" = {
                recursive = true;
                source = ../../config/claude/docs;
              };

              ".claude/commands" = {
                recursive = true;
                source = ../../config/claude/commands;
              };

              ".claude/hooks" = {
                recursive = true;
                source = ../../config/claude/hooks;
              };

              ".claude/scripts" = {
                recursive = true;
                source = ../../config/claude/scripts;
              };

              ".claude/skills" = {
                recursive = true;
                source = ../../config/claude/skills;
              };

              # I need to find a different solution that works with managed the full ~/.claude folder
              ".claude/settings.json.bk" = {
                source = ../../config/claude/settings.json;
                # HACK: https://github.com/nix-community/home-manager/issues/3090#issuecomment-2010891733
                # These file should be editable by claude
                onChange = ''
                  rm -f ${homeDir}/.claude/settings.json
                  cp ${homeDir}/.claude/settings.json.bk ${homeDir}/.claude/settings.json
                '';
              };
            };
          };
        }
      ]);
  };
in {
  # Define modules for both darwin and nixos to import
  flake.modules.darwin.ai = aiModule;
  flake.modules.nixos.ai = aiModule;
}
