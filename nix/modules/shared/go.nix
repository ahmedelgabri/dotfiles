{...}: {
  flake.sharedModules.go = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = with lib; {
      my.env = rec {
        GOPATH = "$XDG_DATA_HOME/go";
        GOBIN = "${GOPATH}/bin";
        GOPRIVATE = "github.com/${config.my.github_username}/*,gitlab.com/${config.my.github_username}/*";
      };

      # all tools from https://github.com/golang/vscode-go/blob/ed92a0c250e8941abb9adab973c129a263ba1e41/src/goToolsInformation.ts
      # my.user = {
      #   packages = with pkgs; [
      #     delve # dlv
      #     go
      #     go-tools # staticcheck
      #     gofumpt
      #     golangci-lint
      #     gomodifytags
      #     gopls
      #     gotests
      #     gotools # goimports
      #     impl
      #     revive
      #   ];
      # };
    };
  };
}
