{ lib, fetchFromGitHub, buildGoModule, icu, source }:

buildGoModule rec {
  pname = "zk";
  version = "0.8.0";

  # TODO is it possibe to pin the hash in flake.lock?
  # This should be doable with https://github.com/tweag/gomod2nix
  vendorSha256 = "sha256-m7QGv8Vx776TsN7QHXtO+yl3U1D573UMZVyg1B4UeIk=";

  doCheck = false;

  src = source;

  buildInputs = [ icu ];

  CGO_ENABLED = 1;

  preBuild = ''buildFlagsArray+=("-tags" "fts5 icu")'';

  ldflags =
    [ "-X=main.Build=${version}" "-X=main.Build=${version}" ];

  meta = with lib; {
    license = licenses.gpl3;
    description = "A zettelkasten plain text note-taking assistant";
    homepage = "https://github.com/mickael-menu/zk";
  };
}
