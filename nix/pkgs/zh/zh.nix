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

  # The cargo setup hook exports LIBSQLITE3_SYS_USE_PKG_CONFIG=1 by default,
  # which overrides rusqlite's `bundled` feature and links a system SQLite
  # that zh does not depend on.
  dontCargoUseSystemLibs = true;

  # The repo-root tests spawn git and jj, each with isolated config; the
  # history tests have zsh write a real history file to read back.
  nativeCheckInputs = [
    git
    jujutsu
    zsh
  ];

  meta = {
    description = "Agent-only shell history recorder and query tool";
    mainProgram = "zh";
  };
}
