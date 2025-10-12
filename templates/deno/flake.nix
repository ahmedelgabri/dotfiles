{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    treefmt-nix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      perSystem = {
        pkgs,
        system,
        ...
      }: {
        # This sets `pkgs` to a nixpkgs with allowUnfree option set.
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        formatter = let
          treefmtEval = treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs = {
              alejandra.enable = true;
              deno.enable = true;
            };
          };
        in
          treefmtEval.config.build.wrapper;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            deno
            treefmt
          ];
          shellHook = ''
            deno eval 'console.log(Deno.version)'
          '';
        };
      };
    };
}
