{
  lib,
  stdenvNoCC,
  makeWrapper,
  luajit,
}:
stdenvNoCC.mkDerivation {
  pname = "mx";
  version = "3.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./mx
      ./mx-init
      ./lua
    ];
  };

  nativeBuildInputs = [ makeWrapper ];

  # tmux comes from the user's PATH, not the closure, so mx always talks to
  # a server of the same version as the client.
  installPhase = ''
    install -Dm755 mx mx-init -t $out/bin
    install -Dm644 lua/*.lua -t $out/share/mx
    for script in mx mx-init; do
      wrapProgram $out/bin/$script --prefix PATH : ${lib.makeBinPath [ luajit ]}
    done
  '';

  meta.mainProgram = "mx";
}
