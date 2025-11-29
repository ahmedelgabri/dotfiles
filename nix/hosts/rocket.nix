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
      mail = rec {
        enable = true;
        account = {
          name = "Miro";
          type = "Work";
          service = "gmail.com";
        };
        imap_server = "imap.gmail.com";
        smtp_server = "smtp.gmail.com";
        source_server = "imaps://gmail.com@${imap_server}";
        outgoing_server = "smtps+plain://gmail.com@${smtp_server}";
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
