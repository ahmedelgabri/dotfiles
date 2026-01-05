# Flake-Parts Migration Guide

> **⚠️ This document is SUPERSEDED by [DENDRITIC-MIGRATION.md](./DENDRITIC-MIGRATION.md)**
>
> This document describes an earlier, incomplete migration step. The configuration has since been migrated to the [Dendritic Pattern](https://github.com/mightyiam/dendritic) which provides a complete aspect-oriented architecture.
>
> **For current documentation, see [DENDRITIC-MIGRATION.md](./DENDRITIC-MIGRATION.md)**

---

## Historical Context

This document describes the initial migration of this Nix configuration from a monolithic flake to a modular flake-parts architecture. This was an intermediate step before the full Dendritic Pattern migration.

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
│   ├── settings.nix                   # Custom options & config (EXTRACTED)
│   ├── shared-configuration.nix       # Shared config for all systems (EXTRACTED)
│   ├── overlays.nix                   # Nixpkgs overlays (EXTRACTED)
│   ├── modules/
│   │   ├── shared/                    # Shared feature modules (shell, git, vim, etc)
│   │   └── darwin/                    # Darwin-specific modules
│   └── hosts/                         # Host-specific configs
```

#### Module Breakdown

**`nix/settings.nix`** (Extracted from `nix/modules/shared/`)
- Defines custom `config.my.*` options (username, timezone, email, etc.)
- Sets up home-manager aliases (`my.hm.file`, `my.hm.configFile`, etc.)
- Configures XDG directories (platform-aware)
- Environment variable management
- Platform-specific home directory logic (Darwin vs Linux)

This is a NixOS/nix-darwin module that defines reusable options and configuration used across all systems.

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

1. **`nix/settings.nix`**: Custom options and config applied to ALL systems
2. **`nix/shared-configuration.nix`**: Core system config applied to ALL systems (Darwin and NixOS)
3. **`nix/overlays.nix`**: Package customizations applied to ALL systems
4. Platform-specific logic handled via `pkgs.stdenv.isDarwin` conditionals

All systems share the same:
- Custom options (`config.my.*`)
- Nix settings and configuration
- Overlays and custom packages
- Base home-manager configuration
- XDG directory structure

## Benefits of This Migration

1. **Modularity**: Each concern is in its own file
2. **Maintainability**: Easier to understand and modify
3. **Reduced Boilerplate**: flake-parts handles system iteration automatically
4. **Standard Patterns**: Follows flake-parts conventions
5. **Single Source of Truth**: shared-configuration.nix applies universally
6. **Better Organization**: Clear separation between flake outputs and system modules

## Extracted Core Modules

Three core modules have been extracted to the `nix/` directory for better organization:

**`nix/settings.nix`** (moved from `nix/modules/shared/settings.nix`)
- Defines custom `config.my.*` options
- Sets up home-manager aliases
- Configures XDG directories
- Manages environment variables
- Platform-aware home directory logic

**`nix/shared-configuration.nix`** (extracted from `sharedConfiguration` function)
- Core Nix daemon settings
- Cache configuration
- Font packages
- System-wide settings

**`nix/overlays.nix`** (extracted from `sharedConfiguration` function)
- All package overlays and customizations

These are NixOS/nix-darwin modules (not flake-parts modules), imported directly by system configurations. The content remains functionally identical, only the organization has changed.

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
