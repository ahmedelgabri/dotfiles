# Dendritic Pattern Migration

This document describes the migration to the [Dendritic Pattern](https://github.com/mightyiam/dendritic) - an architectural approach for organizing Nix configurations using flake-parts where **every file is a flake-parts module**.

## What is the Dendritic Pattern?

The Dendritic Pattern treats each `.nix` file as a top-level flake-parts module. Instead of separating code by configuration type (NixOS, nix-darwin, home-manager), you organize by **feature** or **aspect**. Each module can contribute to multiple configuration types simultaneously.

### Core Principles

1. **Every file is a flake-parts module** - auto-discovered and imported
2. **Feature modules** define `flake.modules.{darwin,nixos,homeManager}.<name>`
3. **Host modules** import features and define system configurations
4. **No specialArgs anti-pattern** - access `inputs.self.modules.*` directly
5. **Cross-cutting concerns** - one file can configure multiple systems

## Architecture Overview

```
├── flake.nix                    # Auto-discovery + mkFlake
├── modules/
│   ├── lib.nix                  # Helper functions (mkDarwin, mkNixos, mkHome)
│   ├── overlays.nix             # perSystem overlays
│   ├── dev-shells.nix           # perSystem devShells
│   ├── apps.nix                 # perSystem apps + formatter
│   │
│   ├── system/                  # System-level feature modules
│   │   ├── settings.nix         # flake.modules.{darwin,nixos}.settings
│   │   ├── nix.nix              # flake.modules.{darwin,nixos}.nix
│   │   ├── fonts.nix            # flake.modules.{darwin,nixos}.fonts
│   │   └── darwin-defaults.nix  # flake.modules.darwin.defaults
│   │
│   ├── programs/                # Program feature modules
│   │   ├── git.nix              # flake.modules.{darwin,nixos,homeManager}.git
│   │   └── ...                  # More programs to be migrated
│   │
│   └── hosts/                   # Host configurations
│       ├── alcantara/
│       │   ├── configuration.nix   # flake.modules.darwin.alcantara
│       │   └── flake-parts.nix     # flake.darwinConfigurations.alcantara
│       ├── pandoras-box/
│       ├── rocket/
│       └── nixos/
```

## How It Works

### 1. Auto-Discovery

The `importTree` function in `flake.nix` recursively imports all `.nix` files:

```nix
importTree = dir: let
  # Recursively find all .nix files (excluding _private dirs)
  # Returns a flattened list of paths
in
  flatten (mapAttrsToList toImport (filterAttrs isValid entries));
```

Usage:
```nix
imports = importTree ./modules;  # Auto-imports all modules
```

### 2. Feature Modules

Feature modules define reusable configuration that can be imported by any host:

```nix
# modules/programs/git.nix
{...}: let
  systemGitModule = {pkgs, ...}: {
    environment.systemPackages = [pkgs.git];
  };

  homeGitModule = {config, lib, ...}: {
    programs.git = {
      enable = lib.mkDefault true;
      userName = config.my.name;
      userEmail = config.my.email;
    };
  };
in {
  # Darwin system-level
  flake.modules.darwin.git = systemGitModule;

  # NixOS system-level
  flake.modules.nixos.git = systemGitModule;

  # Home-manager (works on both)
  flake.modules.homeManager.git = homeGitModule;
}
```

**Key points:**
- Feature modules define `flake.modules.*`
- They have **no knowledge of hosts**
- They can contribute to darwin, nixos, and homeManager simultaneously
- Reusable across all systems

### 3. Host Configuration Modules

Host modules import features and define host-specific configuration:

```nix
# modules/hosts/alcantara/configuration.nix
{inputs, ...}: {
  flake.modules.darwin.alcantara = {config, pkgs, ...}: {
    # Import feature modules via inputs.self.modules.darwin
    imports = with inputs.self.modules.darwin; [
      settings      # Custom options
      nix          # Nix daemon config
      fonts        # Fonts
      defaults     # macOS defaults
      git          # Git
    ];

    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.agenix.darwinModules.default
    ];

    # Host-specific config
    networking.hostName = "alcantara";

    # Home-manager for this host
    home-manager.users.${config.my.username}.imports =
      with inputs.self.modules.homeManager; [
        git
      ];
  };
}
```

### 4. Host Flake-Parts Modules

Each host has a `flake-parts.nix` that creates the actual configuration:

```nix
# modules/hosts/alcantara/flake-parts.nix
{inputs, ...}: {
  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "aarch64-darwin" "alcantara";
}
```

This uses the helper from `modules/lib.nix` which pulls in `inputs.self.modules.darwin.alcantara`.

### 5. Helper Functions

The `lib.nix` module provides helpers for creating configurations:

```nix
# modules/lib.nix
{
  flake.lib = {
    mkDarwin = system: name: {
      ${name} = inputs.darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          {nixpkgs.hostPlatform = lib.mkDefault system;}
        ];
      };
    };

    mkNixos = system: name: { /* similar */ };
    mkHome = system: name: { /* similar */ };
  };
}
```

### 6. perSystem Outputs

Overlays, dev shells, and apps use `perSystem`:

```nix
# modules/overlays.nix
{inputs, ...}: {
  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [/* ... */];
    };
  };
}
```

## Benefits

### 1. **Aspect-Oriented Organization**

Instead of:
```
nix/
├── darwin/     # Darwin stuff
├── nixos/      # NixOS stuff
└── shared/     # Shared... but how to use it?
```

You get:
```
modules/
├── programs/git.nix    # Git for ALL systems
├── programs/vim.nix    # Vim for ALL systems
└── system/nix.nix      # Nix config for ALL systems
```

### 2. **No Special Args Anti-Pattern**

Instead of passing values through `specialArgs` and `extraSpecialArgs`, modules access `inputs.self.modules.*` directly at the top level.

### 3. **Cross-Cutting Concerns**

One file can configure:
- System-level packages (darwin/nixos)
- Home-manager configuration
- Per-system outputs (packages, apps)
- All in one place!

### 4. **Flexibility**

- Rename/move files freely
- No rigid directory structure
- Organize by mental model
- Easy to refactor

### 5. **Discoverability**

All modules auto-discovered - just add a `.nix` file and it's imported. No manual import lists to maintain.

## Migration Status

### ✅ Completed

- ✅ Auto-discovery function (`importTree`)
- ✅ Helper functions (`lib.nix`)
- ✅ Per-system outputs (overlays, devShells, apps)
- ✅ System feature modules (settings, nix, fonts, darwin-defaults)
- ✅ Example program module (git)
- ✅ All host configurations (alcantara, pandoras-box, rocket, nixos)

### 🚧 To Do

- [ ] Migrate all program modules from `nix/modules/shared/` to `modules/programs/`
- [ ] Create darwin-specific modules (hammerspoon, karabiner)
- [ ] Migrate all feature modules to use `flake.modules.*` pattern
- [ ] Remove old `nix/` directory structure (after migration complete)
- [ ] Update documentation

## How to Add a New Feature

### 1. Create a feature module:

```nix
# modules/programs/tmux.nix
{...}: {
  flake.modules.darwin.tmux = {/* darwin config */};
  flake.modules.nixos.tmux = {/* nixos config */};
  flake.modules.homeManager.tmux = {/* home config */};
}
```

### 2. Import in host:

```nix
# modules/hosts/alcantara/configuration.nix
{inputs, ...}: {
  flake.modules.darwin.alcantara = {
    imports = with inputs.self.modules.darwin; [
      /* ... */
      tmux  # Just add it here
    ];

    home-manager.users.ahmed.imports = with inputs.self.modules.homeManager; [
      tmux  # And here for home-manager
    ];
  };
}
```

### 3. Done!

The file is auto-discovered, the module is defined, hosts import it. No manual wiring needed.

## Resources

- [Dendritic Pattern](https://github.com/mightyiam/dendritic) - Original pattern
- [Dendritic Design Guide](https://github.com/Doc-Steve/dendritic-design-with-flake-parts) - Comprehensive guide
- [NixOS Discourse: Every file is a flake-parts module](https://discourse.nixos.org/t/pattern-every-file-is-a-flake-parts-module/61271)
- [flake-parts Documentation](https://flake.parts/)
- [import-tree](https://github.com/vic/import-tree) - Alternative auto-discovery tool

## Example: Cross-Cutting Module

Here's a module that demonstrates the power of the Dendritic Pattern:

```nix
# modules/features/example.nix
{inputs, lib, config, ...}: let
  # perSystem: Build a package for all systems
  perSystem = {pkgs, ...}: {
    packages.example = pkgs.mkDerivation {
      src = inputs.example-program-src;
    };
  };

  # Options: Define options at the top level
  opts.features.example = {
    enable = lib.mkEnableOption "Example feature";
    port = lib.mkOption {
      type = lib.types.port;
      default = 12345;
    };
  };

  # Get config for conditional logic
  conf = config.features.example;
in {
  options = opts;

  # Only configure if enabled
  config = lib.mkIf conf.enable {
    inherit flake perSystem;
  };

  # NixOS systemd unit
  flake.modules.nixos.example = {
    systemd.services.example = {/* ... */};
  };

  # Darwin launch agent
  flake.modules.darwin.example = {
    launchd.agents.example = {/* ... */};
  };

  # Home-manager config
  flake.modules.homeManager.example = {pkgs, ...}: {
    home.packages = [inputs.self.packages.${pkgs.system}.example];
    home.file.".config/example/settings".text = "port = ${toString conf.port}";
  };
}
```

This single file:
- Builds a package (perSystem)
- Defines options (options)
- Configures NixOS (flake.modules.nixos)
- Configures Darwin (flake.modules.darwin)
- Configures home-manager (flake.modules.homeManager)

All coordinated by one enable option!
