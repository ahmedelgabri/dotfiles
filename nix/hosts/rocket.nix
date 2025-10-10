{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (config.home-manager.users."${config.my.username}") xdg;
in {
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
      aerc = {
        enable = true;
        account = {
          name = "Miro";
          type = "Work";
          service = "gmail.com";
        };
        source_server = "imaps://gmail.com@imap.gmail.com";
        outgoing_server = "smtps+plain://gmail.com@smtp.gmail.com";
      };
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
    ];

    brews = [
      "go-task"
      "jiratui"
    ];
  };
}
