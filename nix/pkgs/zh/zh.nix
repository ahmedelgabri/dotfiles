{
  lib,
  rustPlatform,
  git,
  jujutsu,
  zsh,
}:
rustPlatform.buildRustPackage {
  pname = "zh";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src
      ./tests
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  # The repo-root tests spawn git and jj, each with isolated config; the
  # history tests have zsh write a real history file to read back.
  nativeCheckInputs = [
    git
    jujutsu
    zsh
  ];

  # The Claude/Codex hooks, the pi extension and the Ctrl-R widget still
  # call `agent-history`; the alias keeps them working until they call `zh`.
  postInstall = ''
    ln -s zh $out/bin/agent-history
  '';

  meta = {
    description = "Agent-only shell history recorder and query tool";
    mainProgram = "zh";
  };
}
