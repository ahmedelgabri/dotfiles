{
  inputs,
  lib,
  flake-parts-lib,
  ...
}: {
  options = {
    flake = flake-parts-lib.mkSubmoduleOptions {
      lib = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified;
        default = {};
      };

      modules = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
        default = {};
      };

      # darwinConfigurations fix
      darwinConfigurations = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        default = {};
      };
    };
  };

  config.flake.lib = let
    m = inputs.self.modules;
    hm = m.homeManager;

    has = scope: name: builtins.hasAttr name scope;
    get = scope: name: builtins.getAttr name scope;

    # Resolve an optional Home Manager module for a feature name.
    # Returns a singleton list when present so callers can concatMap it.
    hmModuleFor = name:
      if has hm name
      then [(get hm name)]
      else [];

    # Resolve the system module for a feature name for a given runtime.
    # Prefer runtime-specific modules first, then fall back to generic ones.
    # Missing features are skipped.
    systemModuleFor = runtime: name: let
      runtimeModules = get m runtime;
    in
      if has runtimeModules name
      then [(get runtimeModules name)]
      else if has m.generic name
      then [(get m.generic name)]
      else [];

    mkHmImports = imports: {config, ...}: {
      home-manager.users."${config.my.username}".imports = imports;
    };
  in {
    mkDarwin = system: name: {
      ${name} = inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          inputs.self.modules.darwin.${name}
          {nixpkgs.hostPlatform = lib.mkDefault system;}
        ];
      };
    };

    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          inputs.self.modules.nixos.${name}
          {nixpkgs.hostPlatform = lib.mkDefault system;}
        ];
      };
    };

    # Turn a list of feature names into a concrete module that imports:
    # - runtime/generic system modules for each feature
    # - matching Home Manager modules when they exist
    mkFeatureModule = runtime: {features}: let
      hmImports = lib.concatMap hmModuleFor features;
    in {
      imports =
        lib.concatMap (systemModuleFor runtime) features
        ++ lib.optional (hmImports != []) (mkHmImports hmImports);
    };
  };
}
