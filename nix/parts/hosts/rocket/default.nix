{ inputs, ... }:
let
  hostConfiguration =
    { pkgs, ... }:
    {
      # No networking.hostName/computerName: Kandji owns this machine's names
      # (its Device Name enforcement resets ComputerName to the serial number
      # at every check-in), so nothing here manages or reads them. The logical
      # host name comes from my.hostName, set by mk-host.

      ids.gids.nixbld = 30000;

      my = {
        username = "ahmedelgabri";
        email = "ahmed@miro.com";
        website = "https://miro.com";
        company = "Miro";
        devFolder = "dev";
        modules = {
          mail = {
            accounts = [
              {
                name = "Work";
                email = "ahmed@miro.com";
                service = "gmail.com";
                mode = "remote";
                mbsync = {
                  extra_exclusion_patterns = ''!"Version Control" !"Version Control/*" !GitHub !GitHub/* !"Inbox - CC" "!Inbox - CC/*" ![Gmail]* !Sent !Spam !Starred !Archive'';
                };
              }
            ];
          };
        };
        user = {
          packages = with pkgs; [
            graph-easy
            graphviz
            mermaid-cli
            git-filter-repo
            git-sizer
            httpstat
            k9s
            lazydocker
            llm-agents.gemini-cli
            himalaya
            acli
          ];
        };
      };

      homebrew = {
        taps = [
          "openai/tools"
          "JetBrains/homebrew-utils"
          "docker/homebrew-tap"
        ];

        casks = [
          "loom"
          "docker-desktop"
          "ngrok"
          "figma"
          "visual-studio-code"
          "google-chrome"
          "cursor"
          "sbx"
        ];

        brews = [
          "socat"
          "kotlin-lsp"
        ];
      };
    };

in
import ../mk-host.nix {
  inherit inputs hostConfiguration;
  runtime = "darwin";
  name = "rocket";
}
