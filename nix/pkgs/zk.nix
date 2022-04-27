{ lib, fetchFromGitHub, buildGoModule, icu, source }:

buildGoModule rec {
  pname = "zk";
  version = "master";

  # TODO is it possibe to pin the hash in flake.lock?
  # This should be doable with https://github.com/tweag/gomod2nix
  vendorSha256 = "sha256-cTbHlF2hLRM8nybUNtq+k8ueGUND6DwRUHUaSWoyI9w=";

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
