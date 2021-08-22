{ lib, fetchFromGitHub, buildGoModule, icu, source }:

buildGoModule rec {
  pname = "zk";
  version = "0.6.0";

  # TODO is it possibe to pin the hash in flake.lock?
  # This should be doable with https://github.com/tweag/gomod2nix
  vendorSha256 = "sha256-uFY+b8NcpRmnEsVkVq9uy3Ae3aH+jHpuFnY1CoaZggg=";

  doCheck = false;

  src = source;

  buildInputs = [ icu ];

  CGO_ENABLED = 1;

  preBuild = ''buildFlagsArray+=("-tags" "fts5 icu")'';

  buildFlagsArray =
    [ "-ldflags=-X=main.Build=${version} -X=main.Build=${version}" ];

  meta = with lib; {
    license = licenses.gpl3;
    description = "A zettelkasten plain text note-taking assistant";
    homepage = "https://github.com/mickael-menu/zk";
  };
}
