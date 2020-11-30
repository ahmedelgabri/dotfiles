self: super:

let

  pkgs = import <nixpkgs> { };

in rec {
  neovim-unwrapped = super.neovim-unwrapped.overrideAttrs (oldAttrs: {
    version = "master";
    src = builtins.fetchGit { url = "https://github.com/neovim/neovim.git"; };
    buildInputs = oldAttrs.buildInputs ++ ([ pkgs.tree-sitter ]);
  });

  pure-prompt = super.pure-prompt.overrideAttrs
    (old: { patches = (old.patches or [ ]) ++ [ ./pure-zsh.patch ]; });

  zoxide = super.zoxide.overrideAttrs (old: {
    postInstall = ''
      mkdir -p $out/hook

      echo "unalias zi 2> /dev/null" > $out/hook/zoxide-hook.zsh && $out/bin/zoxide init zsh --hook pwd >> $out/hook/zoxide-hook.zsh'';
  });

  # direnv = super.direnv.overrideAttrs (old: {
  #   postInstall = ''
  #     mkdir -p $out/dhook
  #
  #     ${pkgs.direnv}/bin/direnv hook zsh
  #
  #     ${pkgs.direnv}/bin/direnv hook zsh > $out/dhook/direnv-hook.zsh'';
  # });
}
