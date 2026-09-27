{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          name = "dotfiles";
          packages =
            with pkgs;
            [
              typos
              typos-lsp
              nixfmt-rs
              inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
              typescript
            ]
            ++ lib.optional stdenv.hostPlatform.isDarwin sb;
        };

        go = pkgs.mkShell {
          name = "dotfiles-go";
          packages = with pkgs; [
            go
            gopls
            go-tools
            gomodifytags
            gotools
          ];
        };

        rust = pkgs.mkShell {
          name = "dotfiles-rust";
          packages = with pkgs; [
            cargo
            rustc
            rustfmt
            clippy
            rust-analyzer
            # nix/pkgs/zh tests spawn both to find repo roots.
            jujutsu
            git
          ];
        };
      };
    };
}
