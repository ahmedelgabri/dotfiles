{pkgs, ...}: {
  networking = {hostName = "rocket";};
  ids.gids.nixbld = 30000;

  my = {
    username = "ahmedelgabri";
    email = "ahmed@miro.com";
    website = "https://miro.com";
    modules = {
      gpg.enable = true;
      mail = {
        enable = true;
        account = "Work";
        alias_path = "";
        keychain = {name = "gmail.com";};
        imap_server = "imap.gmail.com";
        smtp_server = "smtp.gmail.com";
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
      ];
    };
    env = {
      WORK = "$HOME/dev/work";
      CDPATH = ".:~:~/dev";
    };
  };

  homebrew = {
    casks = [
      "loom"
      "docker"
      "ngrok"
      "figma"
      "visual-studio-code"
      "google-chrome"
    ];

    brews = [
      "go-task"
    ];
  };
}
