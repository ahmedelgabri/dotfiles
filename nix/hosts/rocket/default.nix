{pkgs, ...}: {
  networking = {hostName = "rocket";};
  ids.gids.nixbld = 30000;

  my = {
    username = "ahmedelgabri";
    email = "ahmed@miro.com";
    website = "https://miro.com";
    company = "Miro";
    devFolder = "dev";
    modules = {
      gpg.enable = true;
      mail = {
        enable = true;
        accounts = [
          {
            name = "Work";
            email = "ahmed@miro.com";
            service = "gmail.com";
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
        nodePackages.mermaid-cli
        jira-cli-go
        git-filter-repo
        git-lfs
        git-sizer
        httpstat
        k9s
        lazydocker
        mise
      ];
    };
  };

  homebrew = {
    casks = [
      "loom"
      "docker-desktop"
      "ngrok"
      "figma"
      "visual-studio-code"
      "google-chrome"
      "cursor"
      "claude-code"
      "superwhisper"
    ];

    brews = [
      "go-task"
      "jiratui"
    ];
  };
}
