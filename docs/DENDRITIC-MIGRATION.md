# Dendritic Pattern Migration - COMPLETED ✅

This document describes the completed migration to the [Dendritic Pattern](https://github.com/mightyiam/dendritic) - an architectural approach for organizing Nix configurations using flake-parts where **every file is a flake-parts module**.

## What is the Dendritic Pattern?

The Dendritic Pattern treats each `.nix` file as a top-level flake-parts module. Instead of separating code by configuration type (NixOS, nix-darwin, home-manager), you organize by **feature** or **aspect**. Each module can contribute to multiple configuration types simultaneously.

### Core Principles

1. **Every file is a flake-parts module** - auto-discovered via import-tree
2. **Feature modules** define `flake.modules.{darwin,nixos,homeManager}.<name>`
3. **Host modules** import features via `inputs.self.modules.*`
4. **No specialArgs anti-pattern** - access modules directly
5. **Cross-cutting concerns** - one file can configure multiple systems
6. **Aspect-oriented organization** - organize by feature, not by platform
7. **Import = enable** - no `.enable` flags, importing a module enables it

## Final Architecture

```
├── flake.nix                    # Auto-discovery + mkFlake
├── nix/
│   ├── lib.nix                  # Helper functions (mkDarwin, mkNixos)
│   ├── overlays.nix             # perSystem overlays
│   ├── dev-shells.nix           # perSystem devShells
│   ├── apps.nix                 # perSystem apps
│   │
│   ├── system/                  # System-level modules (6 files)
│   │   ├── user-options.nix         # config.my.* options
│   │   ├── nix-daemon.nix           # Nix daemon config
│   │   ├── state-version.nix        # State version management
│   │   ├── home-manager-integration.nix  # Home-manager setup
│   │   ├── fonts.nix                # Font configuration
│   │   └── darwin-defaults.nix      # macOS system defaults
│   │
│   ├── modules/                # Feature modules (26 files)
│   │   ├── git.nix              # flake.modules.{darwin,nixos}.git
│   │   ├── vim.nix              # flake.modules.{darwin,nixos}.vim
│   │   ├── tmux.nix             # flake.modules.{darwin,nixos}.tmux
│   │   ├── ssh.nix              # flake.modules.{darwin,nixos}.ssh
│   │   ├── gpg.nix              # flake.modules.{darwin,nixos}.gpg
│   │   ├── user-shell.nix       # flake.modules.{darwin,nixos}.shell
│   │   ├── kitty.nix            # Terminal emulator
│   │   ├── ghostty.nix          # Terminal emulator
│   │   ├── yazi.nix             # File manager
│   │   ├── bat.nix              # Better cat
│   │   ├── ripgrep.nix          # Better grep
│   │   ├── mpv.nix              # Media player
│   │   ├── yt-dlp.nix           # YouTube downloader
│   │   ├── mail.nix             # Email (aerc, mbsync, notmuch)
│   │   ├── gui.nix              # GUI applications
│   │   ├── discord.nix          # Discord
│   │   ├── ai.nix               # AI tools (ollama, claude-code)
│   │   ├── zk.nix               # Zettelkasten
│   │   ├── node.nix             # Node.js environment
│   │   ├── python.nix           # Python environment
│   │   ├── go.nix               # Go environment
│   │   ├── rust.nix             # Rust environment
│   │   ├── misc.nix             # Miscellaneous configs
│   │   ├── agenix.nix           # Age encryption
│   │   ├── hammerspoon.nix      # flake.modules.darwin.hammerspoon
│   │   └── karabiner.nix        # flake.modules.darwin.karabiner
│   │
│   ├── hosts/                   # Host configurations (4 hosts)
│   │   ├── alcantara/
│   │   │   └── default.nix      # aarch64-darwin (personal)
│   │   ├── pandoras-box/
│   │   │   └── default.nix      # x86_64-darwin (personal)
│   │   ├── rocket/
│   │   │   └── default.nix      # aarch64-darwin (work - Miro)
│   │   └── nixos/
│   │       ├── flake-module.nix # x86_64-linux flake config
│   │       ├── configuration.nix # NixOS system config
│   │       ├── hardware.nix     # Hardware configuration
│   │       └── dwm.patch
│   │
│   ├── pkgs/                    # Custom packages
│   │   └── _definitions/        # Package definitions (excluded from import-tree)
│   │       ├── hcron.nix
│   │       └── pragmatapro.nix
│   │
│   └── secrets/                 # Age-encrypted secrets
│       ├── secrets.nix          # flake-parts module (auto-discovered)
│       └── npmrc.age            # Secret file
```

## How It Works

### 1. Auto-Discovery with import-tree

All modules under `nix/` are auto-discovered using the official [import-tree](https://github.com/vic/import-tree) package:

```nix
# flake.nix
inputs.import-tree.url = "github:vic/import-tree";

outputs = inputs @ {flake-parts, import-tree, ...}:
  flake-parts.lib.mkFlake {inherit inputs;} {
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    imports = [(import-tree ./nix)];  # Auto-discover all modules!
    flake.templates = import ./templates;
  };
```

### 2. Feature Modules (No Enable Pattern)

Feature modules define reusable configuration that works across platforms. **Import = enable**:

```nix
# nix/modules/git.nix
{inputs, ...}: let
  gitModule = {pkgs, lib, config, ...}: {
    config = {
      environment.systemPackages = with pkgs; [git];
      my.user.packages = with pkgs; [delta hub gh tig];

      my.hm.file = {
        ".config/git" = {
          recursive = true;
          source = ../../config/git;
        };
      };

      # Git-specific config using config.my.* options
      programs.git = {
        enable = true;
        userName = config.my.name;
        userEmail = config.my.email;
      };
    };
  };
in {
  # Define modules for both darwin and nixos
  flake.modules.darwin.git = gitModule;
  flake.modules.nixos.git = gitModule;
}
```

**Key points:**
- Each feature is self-contained
- No `enable` option - import IS the enable
- Shared modules work on both darwin and nixos
- Darwin-only modules (hammerspoon, karabiner) only define `flake.modules.darwin.*`
- Features have **no knowledge of hosts**
- Configuration can reference `config.my.*` options for customization

### 3. System Modules

System modules provide core configuration and options:

```nix
# nix/system/user-options.nix
{lib, ...}: let
  userOptionsModule = {config, pkgs, options, ...}: {
    options.my = with lib; {
      name = mkOption {type = types.str; default = "Ahmed El Gabri";};
      username = mkOption {type = types.str; default = "ahmed";};
      email = mkOption {type = types.str; default = "ahmed@gabri.me";};
      # ... more options
    };
  };
in {
  flake.modules.darwin.user-options = userOptionsModule;
  flake.modules.nixos.user-options = userOptionsModule;
}
```


### 4. Host Configuration

Host modules explicitly import system modules, feature modules, and external modules:

```nix
# nix/hosts/alcantara/default.nix
{inputs, ...}: {
  flake.modules.darwin.alcantara = {config, pkgs, ...}: {
    imports =
      [
        inputs.home-manager.darwinModules.home-manager
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.agenix.darwinModules.default
      ]
      ++ (with inputs.self.modules.darwin; [
        user-options
        nix-daemon
        state-version
        home-manager-integration
        fonts
        defaults
        shell
        git
        vim
        tmux
        ssh
        gpg
        kitty
        ghostty
        yazi
        bat
        ripgrep
        mpv
        yt-dlp
        gui
        zk
        ai
        agenix
        misc
        node
        python
        go
        rust
        hammerspoon
        karabiner
        mail
        discord
      ]);

    networking.hostName = "alcantara";

    # Host-specific packages
    my.user.packages = with pkgs; [
      amp-cli
      codex
      opencode
    ];

    # Host-specific homebrew casks
    homebrew.casks = [
      "jdownloader"
      "signal"
      "monodraw"
      "sony-ps-remote-play"
      "helium-browser"
    ];

    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [];
  };

  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "aarch64-darwin" "alcantara";
}
```

### 5. Helper Functions

The `lib.nix` module provides helpers for creating configurations:

```nix
# nix/lib.nix
{inputs, lib, ...}: {
  flake.lib = {
    mkDarwin = system: name: {
      ${name} = inputs.darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          {nixpkgs.hostPlatform = lib.mkDefault system;}
        ];
      };
    };

    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          {nixpkgs.hostPlatform = lib.mkDefault system;}
        ];
      };
    };
  };
}
```

### 6. perSystem Outputs

Overlays, dev shells, and apps use `perSystem`:

```nix
# nix/overlays.nix
{inputs, ...}: {
  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        inputs.yazi.overlays.default
        inputs.nur.overlays.default
        (final: prev: {
          # Custom packages defined once in overlays
          pragmatapro = prev.callPackage ./pkgs/_definitions/pragmatapro.nix {};
          hcron = prev.callPackage ./pkgs/_definitions/hcron.nix {};
          # ... more packages
        })
      ];
    };
  };
}
```

### 7. Packages and Secrets

**Packages** are defined in `nix/pkgs/_definitions/` (excluded from import-tree) and exposed via overlays:

```nix
# nix/pkgs/_definitions/hcron.nix
{fetchurl, stdenvNoCC}:
stdenvNoCC.mkDerivation rec {
  name = "hcron";
  version = "1.1.1";
  # ... package definition
}
```

**Secrets** are managed via a flake-parts module:

```nix
# nix/secrets/secrets.nix
{inputs, ...}: let
  # SSH keys for hosts and users
  rocket = "ssh-ed25519 ...";
  alcantara = "ssh-ed25519 ...";
  personal = "ssh-ed25519 ...";

  allKeys = [rocket alcantara personal];
in {
  flake.age.secrets = {
    "npmrc.age".publicKeys = allKeys;
  };
}
```

## Migration Summary

### What Changed

**Before:**
```
nix/
├── modules/
│   ├── shared/default.nix       # Imports and defaults with lib.mkDefault
│   ├── shared/git.nix            # Old module with .enable
│   ├── shared/vim.nix            # Old module with .enable
│   └── ...
└── system/feature-defaults.nix  # Defaults pattern
```

**After:**
```
nix/
├── modules/                     # Feature modules (26 files)
│   ├── git.nix                   # No .enable, import = enable
│   ├── vim.nix                   # No .enable, import = enable
│   └── ...                       # All features migrated
├── system/                       # System modules (6 files)
├── hosts/                        # Explicit imports per host
├── pkgs/_definitions/            # Excluded from import-tree
└── secrets/
    └── secrets.nix              # Auto-discovered flake-parts module
```

### Modules Migrated (26 feature modules)

**Shared modules (24)** - work on both darwin and nixos:
- Core: git, vim, tmux, ssh, gpg, user-shell
- Terminal: kitty, ghostty, yazi, bat, ripgrep
- Development: node, python, go, rust
- Applications: gui, mail, discord, ai, zk, mpv, yt-dlp
- Utilities: misc, agenix

**Darwin-only modules (2)**:
- hammerspoon, karabiner

**System modules (6)**:
- user-options, nix-daemon, state-version, home-manager-integration, fonts, darwin-defaults

### Key Improvements

1. **✅ No enable pattern** - Import statement IS the opt-in
2. **✅ Single file per feature** - Each feature is self-contained
3. **✅ Auto-discovery** - All modules discovered via import-tree
4. **✅ Aspect-oriented** - Organized by feature, not platform
5. **✅ Explicit imports** - Each host explicitly lists what modules it uses
6. **✅ Clean separation** - Features, system, and hosts clearly separated
7. **✅ No specialArgs** - Access modules via `inputs.self.modules.*`
8. **✅ No underscore files** - Only `_definitions/` subdirectory excluded

## Benefits

### 1. **Aspect-Oriented Organization**

Instead of organizing by platform (darwin/nixos/shared), organize by what it does:
- `modules/git.nix` - Git configuration for ALL systems
- `modules/vim.nix` - Vim configuration for ALL systems
- `system/nix-daemon.nix` - Nix daemon for ALL systems

### 2. **No Special Args Anti-Pattern**

Features are accessed via `inputs.self.modules.darwin.<name>` instead of passing through specialArgs.

### 3. **Cross-Cutting Concerns**

One file can configure:
- System-level packages (darwin/nixos)
- Environment variables
- Configuration files
- All in one place!

### 4. **Flexibility**

- Easy to rename/move files
- No rigid directory structure
- Organize by mental model
- Easy to refactor

### 5. **Discoverability**

All modules auto-discovered - just add a `.nix` file and it's imported. No manual import lists to maintain.

### 6. **Simplicity**

- No `.enable` flags to manage
- Importing a module = enabling it
- Clearer intent in host configurations

## Usage

### Building Configurations

```bash
# Darwin systems
nix build .#darwinConfigurations.alcantara.system
nix build .#darwinConfigurations.pandoras-box.system
nix build .#darwinConfigurations.rocket.system

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

### Verification

```bash
# Check flake validity
nix flake check

# Show flake outputs
nix flake show

# Update lock file
nix flake update
```

## How to Add a New Feature

### 1. Create a feature module:

```nix
# nix/modules/example.nix
{inputs, ...}: let
  exampleModule = {pkgs, lib, config, ...}: {
    config = {
      # Your configuration here
      my.user.packages = with pkgs; [example-package];

      my.hm.file = {
        ".config/example" = {
          source = ../../config/example;
        };
      };
    };
  };
in {
  # Define for darwin and/or nixos
  flake.modules.darwin.example = exampleModule;
  flake.modules.nixos.example = exampleModule;
}
```

### 2. Import in host:

```nix
# nix/hosts/alcantara/default.nix
imports =
  [...]
  ++ (with inputs.self.modules.darwin; [
    # ... other modules
    example  # Add the module - this enables it!
  ]);
```

### 3. Done!

The module is auto-discovered, imported by the host, and everything just works.

## Testing Checklist

Before deploying changes:

- [ ] `nix flake check` - Validate flake
- [ ] `nix build .#darwinConfigurations.<host>.system --dry-run` - Test build
- [ ] `nix eval .#darwinConfigurations.<host>.config.system.build.toplevel` - Test evaluation
- [ ] Check for import errors in auto-discovered modules
- [ ] Verify relative paths resolve correctly (../../config/)
- [ ] Test activation scripts work correctly
- [ ] Verify home-manager integration works

## Resources

- [Dendritic Pattern](https://github.com/mightyiam/dendritic) - Original pattern
- [Dendritic Design Guide](https://github.com/Doc-Steve/dendritic-design-with-flake-parts) - Comprehensive guide
- [NixOS Discourse: Every file is a flake-parts module](https://discourse.nixos.org/t/pattern-every-file-is-a-flake-parts-module/61271)
- [flake-parts Documentation](https://flake.parts/)
- [import-tree](https://github.com/vic/import-tree) - Auto-discovery tool

## Migration Commits

1. `feat(nix): migrate to Dendritic Pattern architecture` - Initial migration setup
2. `refactor(nix): cleanup and break down modules into focused aspects` - Split monolithic settings.nix
3. `refactor(nix): use import-tree and migrate to nix/ directory` - Added import-tree and restructured
4. `fix(nix): properly migrate pandoras-box and rocket host configs` - Fixed broken host imports
5. `feat(nix): complete migration to flake-parts with Dendritic Pattern` - Complete module migration
6. `refactor(nix): fix migration - use nix/modules, remove feature-defaults, explicit imports` - Corrections and cleanup
7. `docs: organize documentation in docs/ directory` - Move docs to docs/
8. `refactor: remove enable pattern and ensure all files are flake-parts modules` - Remove .enable flags
9. `refactor: migrate underscore files to flake-parts modules` - Convert all files
10. `fix: correct package definitions, secrets location, and NixOS modules` - Final cleanup

## What's Next?

The migration is complete! The configuration now follows the Dendritic Pattern with:
- ✅ Auto-discovery of all modules
- ✅ Aspect-oriented organization
- ✅ Clean separation of concerns
- ✅ Feature-based architecture
- ✅ Single file per host with explicit imports
- ✅ No specialArgs anti-pattern
- ✅ No enable flags - import = enable
- ✅ Cross-platform compatibility
- ✅ All files are flake-parts modules or properly excluded

Future improvements:
- Consider adding more granular feature modules
- Explore flake-parts options for better module composition
- Document common patterns for contributors
- Add CI/CD testing for configuration builds
