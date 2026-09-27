{
  lib,
  rustPlatform,
  git,
  jujutsu,
}:
rustPlatform.buildRustPackage {
  pname = "agent-history";
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

  meta = {
    description = "Agent-only shell history recorder and query tool";
    mainProgram = "agent-history";
  };
}
