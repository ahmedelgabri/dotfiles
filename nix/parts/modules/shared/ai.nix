let
  module = {
    generic = {
      pkgs,
      lib,
      config,
      ...
    }: {
      config = with lib; {
        my.user.packages = with pkgs; [
          llm-agents.claude-code
          llm-agents.qmd
          llm-agents.agent-browser
          llama-cpp
          ccpeek
        ];
      };
    };

    homeManager = {
      lib,
      myConfig,
      config,
      ...
    }:
      with lib; {
        home.file = {
          ".claude/CLAUDE.md".source = ../../../../config/claude/CLAUDE.md;

          ".claude/agents" = {
            recursive = true;
            source = ../../../../config/claude/agents;
          };

          ".claude/docs" = {
            recursive = true;
            source = ../../../../config/claude/docs;
          };

          ".claude/commands" = {
            recursive = true;
            source = ../../../../config/claude/commands;
          };

          ".claude/hooks" = {
            recursive = true;
            source = ../../../../config/claude/hooks;
          };

          ".claude/scripts" = {
            recursive = true;
            source = ../../../../config/claude/scripts;
          };

          ".claude/skills" = {
            recursive = true;
            source = ../../../../config/claude/skills;
          };

          ".claude/settings.json.bk" = {
            source = ../../../../config/claude/settings.json;
            onChange = ''
              rm -f ${config.home.homeDirectory}/.claude/settings.json
              cp ${config.home.homeDirectory}/.claude/settings.json.bk ${config.home.homeDirectory}/.claude/settings.json
            '';
          };
        };
      };
  };
in {
  flake = {
    modules = {
      generic.ai = module.generic;
      homeManager.ai = module.homeManager;
    };
  };
}
