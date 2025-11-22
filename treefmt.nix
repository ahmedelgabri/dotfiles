_: {
  projectRootFile = "flake.nix";

  settings = {
    # Do not exit with error if a configured formatter is missing
    allow-missing-formatter = true;

    # Log paths that did not match any formatters at the specified log level
    # Possible values are <debug|info|warn|error|fatal>
    on-unmatched = "info";

    # The method used to traverse the files within the tree root
    # Currently, we support 'auto', 'git', 'jujutsu', or 'filesystem'
    walk = "git";

    global.excludes = [
      "*.lock"
      "LICENSE"
      "config/nvim/spell/*"
      "config/zsh.d/zsh/config/completion.zsh"
      "config/.hammerspoon/Spoons/*"
      "config/zsh.d/.p10k.zsh"
      "*.ignore"
      "*.gitignore"
    ];
  };

  programs = {
    alejandra.enable = true;
    statix.enable = true;
    stylua.enable = true;
    gofmt.enable = true;
    goimports = {
      enable = true;
      priority = 1;
    };
    ruff-format.enable = true;
    ruff-check = {
      enable = true;
      priority = 1;
    };
    shfmt = {
      enable = true;
      # use the -s flag
      simplify = true;
      includes = ["*.sh" "*.bash" "*.zsh" ".envrc"];
    };
    taplo.enable = true;
    prettier.enable = true;
  };
}
