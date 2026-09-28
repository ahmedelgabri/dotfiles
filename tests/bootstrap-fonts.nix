{ lib, hosts }:
lib.mapAttrs (
  name: host:
  let
    withoutFont = hosts."${name}-without-pragmatapro";
    font = host.pkgs.pragmatapro;
    normalFonts = map toString host.config.fonts.packages;
    bootstrapFonts = map toString withoutFont.config.fonts.packages;
  in
  assert host.config.my.fonts.pragmatapro.enable;
  assert !withoutFont.config.my.fonts.pragmatapro.enable;
  assert builtins.elem (toString font) normalFonts;
  assert bootstrapFonts == builtins.filter (path: path != toString font) normalFonts;
  assert withoutFont.config.my.hostName == host.config.my.hostName;
  assert withoutFont.config.my.username == host.config.my.username;
  true
) (lib.filterAttrs (name: _: !lib.hasSuffix "-without-pragmatapro" name) hosts)
