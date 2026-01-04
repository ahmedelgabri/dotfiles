# Flake-Parts Migration Guide

This document describes the migration of this Nix configuration from a monolithic flake to a modular flake-parts architecture.

## Migration Overview

The configuration has been migrated to use [flake-parts](https://flake.parts), a framework that enables modular Nix flakes using the NixOS module system. This provides better organization, reduced boilerplate, and a single unified configuration for all systems.

## Key Changes

### 1. Added flake-parts Input

```nix
flake-parts = {
  url = "github:hercules-ci/flake-parts";
  inputs.nixpkgs-lib.follows = "nixpkgs";
};
```

### 2. Converted to mkFlake Structure

The main `flake.nix` now uses `flake-parts.lib.mkFlake` instead of a raw outputs function:

```nix
outputs = inputs @ {flake-parts, ...}:
  flake-parts.lib.mkFlake {inherit inputs;} {
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    imports = [
      ./flake-modules/per-system.nix
      ./flake-modules/hosts.nix
    ];
    flake = {
      templates = import ./templates;
    };
  };
```

### 3. Modular Architecture

#### File Structure

```
├── flake.nix                          # Main entrypoint
├── flake-modules/
│   ├── per-system.nix                 # Per-system outputs (formatter, devShells, apps)
│   └── hosts.nix                      # Darwin & NixOS configurations
├── nix/
│   ├── shared-configuration.nix       # Shared config for all systems (NEW)
│   ├── overlays.nix                   # Nixpkgs overlays (NEW)
│   ├── modules/
│   │   ├── shared/                    # Shared modules
│   │   │   └── settings.nix           # Custom options (UNCHANGED)
│   │   └── darwin/                    # Darwin-specific modules
│   └── hosts/                         # Host-specific configs
```

#### Module Breakdown

**`nix/shared-configuration.nix`** (Extracted from original `sharedConfiguration`)
- Core Nix settings (experimental features, substituters, GC)
- Font configuration (platform-specific)
- Timezone configuration
- Documentation settings
- System stateVersion (platform-specific)
- Home-manager base configuration

This is a NixOS/nix-darwin module that gets imported by all system configurations.

**`nix/overlays.nix`**
- All nixpkgs overlays in one place
- Custom packages (pragmatapro, hcron, next-prayer)
- Package overrides (notmuch, zsh plugins)
- Third-party inputs (yazi, nur, gh-gfm-preview, emmylua)

**`flake-modules/per-system.nix`** (flake-parts module)
- Uses `perSystem` for system-specific outputs
- Formatter (alejandra)
- DevShells (default, go)
- Apps (bootstrap)

**`flake-modules/hosts.nix`** (flake-parts module)
- Defines `darwinConfigurations` for macOS systems
- Defines `nixosConfigurations` for Linux systems
- Convenience outputs for easier building

### 4. Single Unified Configuration

The migration achieves a **single Nix configuration that works on any system** managed by the flake:

1. **`nix/shared-configuration.nix`**: Applied to ALL systems (Darwin and NixOS)
2. **`nix/overlays.nix`**: Applied to ALL systems
3. **`nix/modules/shared/settings.nix`**: Custom options available to ALL systems
4. Platform-specific logic handled via `pkgs.stdenv.isDarwin` conditionals

All systems share the same:
- Nix settings
- Overlays and custom packages
- Base home-manager configuration
- Custom options defined in settings.nix

## Benefits of This Migration

1. **Modularity**: Each concern is in its own file
2. **Maintainability**: Easier to understand and modify
3. **Reduced Boilerplate**: flake-parts handles system iteration automatically
4. **Standard Patterns**: Follows flake-parts conventions
5. **Single Source of Truth**: shared-configuration.nix applies universally
6. **Better Organization**: Clear separation between flake outputs and system modules

## settings.nix Unchanged

The `nix/modules/shared/settings.nix` file remains **completely unchanged**. It continues to:
- Define custom `config.my.*` options
- Set up home-manager aliases
- Configure XDG directories
- Manage environment variables

This is because settings.nix is a NixOS/nix-darwin module (not a flake-parts module), and the migration only affects the flake structure, not the system module structure.

## How to Use

### Building Configurations

```bash
# Darwin systems
nix build .#darwinConfigurations.pandoras-box.system
nix build .#darwinConfigurations.alcantara.system
nix build .#darwinConfigurations.rocket.system

# Or use the convenience shortcuts
nix build .#pandoras-box
nix build .#alcantara
nix build .#rocket

# NixOS systems
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

### Activating Configurations

```bash
# Darwin
darwin-rebuild switch --flake .#alcantara

# NixOS
nixos-rebuild switch --flake .#nixos
```

### Development Shells

```bash
# Default shell
nix develop

# Go development shell
nix develop .#go
```

### Formatting

```bash
nix fmt
```

## Verification

To verify the migration:

```bash
# Check flake validity
nix flake check

# Show flake outputs
nix flake show

# Update lock file
nix flake update
```

## Resources

- [flake-parts Documentation](https://flake.parts/)
- [flake-parts GitHub](https://github.com/hercules-ci/flake-parts)
- [NixOS Wiki: Flake Parts](https://wiki.nixos.org/wiki/Flake_Parts)
- [flake-parts Options Reference](https://flake.parts/options/flake-parts.html)

## Rollback

If needed, the previous monolithic flake structure is preserved in git history. To rollback:

```bash
git log --oneline  # Find the commit before migration
git revert <commit-hash>
```
