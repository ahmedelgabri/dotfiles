{ pkgs }:
let
  packages = pkgs.lib.mapAttrsToList (name: package: { inherit name; } // package) (
    builtins.fromJSON (builtins.readFile ./pi-extension-types.lock.json)
  );
in
pkgs.runCommandLocal "pi-agent-extension-node-modules" { } (
  pkgs.lib.concatMapStrings (package: ''
    mkdir -p "$(dirname "$out/${package.name}")" unpack
    tar -xzf ${
      pkgs.fetchurl {
        url = "https://registry.npmjs.org/${package.name}/-/${baseNameOf package.name}-${package.version}.tgz";
        inherit (package) hash;
      }
    } -C unpack
    # Most npm tarballs unpack to package/, but not all (@types/node
    # uses node/), so move whatever single root directory exists.
    mv unpack/* "$out/${package.name}"
    rmdir unpack
  '') packages
)
