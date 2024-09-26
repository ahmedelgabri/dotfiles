{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.go;

in
{
  options = with lib; {
    my.modules.go = {
      enable = mkEnableOption ''
        Whether to enable go module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
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
}
