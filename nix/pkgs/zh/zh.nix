{
  lib,
  rustPlatform,
  git,
  jujutsu,
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

  # The repo-root tests spawn both; each test run isolates their config.
  nativeCheckInputs = [
    git
    jujutsu
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
