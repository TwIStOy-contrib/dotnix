# Coding Agent Instructions for NixOS/nix-darwin Configuration

This document provides essential guidelines for AI coding agents working in this repository.

## Repository Overview

Multi-host, multi-platform NixOS/nix-darwin configuration with 161+ .nix files across 7 hosts (3 macOS, 3 NixOS, 1 ISO). All configuration lives under the `dotnix.*` namespace using a modular architecture.

## Build, Test & Validation Commands

### Primary Commands (via justfile)

```bash
just                    # Deploy to current host (build + activate)
just check              # Validate configuration before deploying
just <hostname>         # Deploy to specific host (yukikaze, poi, taihou, LCNDWWYVTFMFX)
just ci-<hostname>      # CI build check for specific host (no activation)
```

### Formatting & Linting

```bash
just fmt                # Format all .nix files with alejandra
just ci-fmt             # Check formatting (CI mode, no changes)
just ci-eval            # Evaluate all flake outputs (checks for errors)
just ci                 # Run both ci-fmt and ci-eval
```

### Pre-commit Hooks

The repo uses pre-commit hooks (defined in `outputs/default.nix`):
- **alejandra**: Nix code formatter
- **statix**: Nix linter (checks for anti-patterns)
- **actionlint**: GitHub Actions workflow linter

Excludes: `hardware-configuration*.nix`, `.vim-template*` files

### Other Commands

```bash
just up                 # Update flake.lock (nix flake update)
just gc                 # Garbage collect unused nix store entries
nix build .#darwinConfigurations.<host>.system      # Build darwin config
nix build .#nixosConfigurations.<host>.config.system.build.toplevel  # Build NixOS
```

## Code Style Guidelines

### File Organization

**Module Structure Pattern:**
```nix
{
  config,
  lib,
  pkgs,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.category.feature;
in {
  options.dotnix.category.feature = {
    enable = lib.mkEnableOption "Description of feature";
    # Additional options...
  };

  config = lib.mkIf cfg.enable {
    # Configuration goes here
  };
}
```

**Host Structure:**
```
hosts/<hostname>/
├── default.nix       # Entry: lists modules and home-modules arrays
├── modules.nix       # System-level: enables dotnix.* options
├── home.nix          # User-level: home-manager configs
└── hardware-configuration.nix  # (NixOS only)
```

### Naming Conventions

- **Files**: kebab-case (`my-module.nix`)
- **Directories**: kebab-case (`my-feature/`)
- **Options**: camelCase under `dotnix.*` namespace (`dotnix.apps.myApp.enable`)
- **Variables**: camelCase in let bindings (`cfg`, `myVariable`)
- **Constants**: camelCase or snake_case for configuration values

### Imports & Dependencies

**Standard Module Imports:**
```nix
{
  config,        # Current configuration state
  lib,           # nixpkgs library functions
  pkgs,          # Package set
  dotnix-utils,  # Custom utilities (hm.hmConfig, hm.hmModule, path.listModules)
  dotnix-constants,  # User info, environment vars
  pkgs-unstable,     # Unstable nixpkgs (when needed)
  ...
}:
```

**Auto-importing Modules:**
```nix
# In default.nix of a directory
{dotnix-utils, ...}:
{
  imports = dotnix-utils.path.listModules ./.;
}
```

### Formatting Rules (alejandra)

- **2-space indentation** (enforced by alejandra)
- **No trailing whitespace**
- **Function arguments**: One per line with closing brace on same line as last arg OR inline for short lists
- **Let-in blocks**: Variables defined in let, usage in config
- **Attribute sets**: Use `{ }` for empty, `{...}` for pattern matches

**Good Examples:**
```nix
# Short inline
{config, lib, ...}: { }

# Multi-line function args
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dotnix.apps.git;
in { }

# Attribute merging
lib.optionalAttrs condition {
  setting = value;
}
```

### Module Conventions

1. **Enable Option Pattern**: Every module MUST have `enable = lib.mkEnableOption`
2. **Config Guards**: Wrap config in `lib.mkIf cfg.enable { }`
3. **Namespace**: All options under `dotnix.*` (e.g., `dotnix.apps.git`, `dotnix.services.tailscale`)
4. **Auto-discovery**: Every directory's `default.nix` uses `dotnix-utils.path.listModules ./.`
5. **Home-manager Integration**: Use `dotnix-utils.hm.hmConfig { }` or `dotnix-utils.hm.hmModule ./path.nix`

### Type Annotations

Nix is dynamically typed, but use descriptive option types:
```nix
options.dotnix.apps.myApp = {
  enable = lib.mkEnableOption "My application";
  package = lib.mkOption {
    type = lib.types.package;
    default = pkgs.myapp;
    description = "Package to use";
  };
  extraConfig = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Extra configuration";
  };
};
```

### Error Handling

- Use `lib.mkIf` for conditional configuration
- Use `lib.optionalAttrs` for conditional attribute sets
- Use `lib.optionalString` for conditional strings
- Validate with `just check` before committing

### Comments

- Use `#` for single-line comments
- Use `/* */` for multi-line comments
- Comment complex logic and non-obvious configurations
- Don't comment obvious code

## Key Patterns

### Enabling Groups of Modules (Suits)

```nix
dotnix.suits.development.enable = true;  # Enables git, direnv, neovim, LSPs, etc.
```

### Enabling Individual Apps

```nix
dotnix.apps.git.enable = true;
dotnix.desktop.kitty.enable = true;
dotnix.services.tailscale.enable = true;
```

### Using Helpers

```nix
inherit (dotnix-utils) enabled enableModules;

dotnix.apps = enableModules ["git" "neovim" "bat"];
dotnix.services.tailscale = enabled;  # Shorthand for {enable = true;}
```

### Environment Switching

Set in `hosts/<hostname>/default.nix`:
```nix
{
  env = "tesla";  # or "cloud" or omit for "default"
  modules = [ ... ];
  home-modules = [ ... ];
}
```

## Important Constraints

1. **Never modify** `hardware-configuration.nix` (auto-generated)
2. **Never skip** `.vim-template*` files in operations
3. **Always run** `just check` before committing
4. **Format before commit** with `just fmt`
5. **Use nixos-25.11** channel (stable), `pkgs-unstable` for bleeding-edge
6. **Test on target platform** (darwin vs nixos have different modules)
7. **Secrets via agenix** - never commit plaintext secrets

## Special Files to Recognize

- `flake.nix` - Main flake inputs/outputs
- `justfile` - Build automation
- `modules/mkSystem.nix` - System builder (core glue)
- `lib/path.nix` - Module auto-discovery
- `secrets.nix` - Agenix secret definitions
- `outputs/default.nix` - Output orchestration

## When Making Changes

1. Understand the module pattern before creating new modules
2. Follow the existing directory structure
3. Use auto-discovery (don't manually import in most cases)
4. Run `just check` to validate
5. Run `just fmt` to format
6. Test with `just ci-<hostname>` for dry-run
7. Deploy with `just <hostname>` or `just` for current host

## Quick Reference

| Task | Command |
|------|---------|
| Deploy current host | `just` |
| Check config validity | `just check` |
| Format all files | `just fmt` |
| Build without activation | `just ci-<hostname>` |
| Update dependencies | `just up` |
| Run all CI checks | `just ci` |
