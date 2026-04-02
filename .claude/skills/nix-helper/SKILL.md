---
name: nix-helper
description: |
    Use when the user ask to "add a package", "configure a new program", "troubleshoot Nix build errors", "update flake inputs", "add a new host", "manage secrets with agenix", "create out-of-store symlink" or mentions Nix, Home Manager or nix-darwin configuration in this repository.
---

# Nix Helper

Provide guidance for managing Nix configuration in this repository.

## Directory Structure

```
dotnix/
     ├── flake.nix              # Main flake definition (inputs/outputs)
     ├── flake.lock             # Locked dependency versions
     ├── justfile               # Build automation recipes
     ├── constants.nix          # User constants and environment variables
     ├── constants-work.nix     # Work-specific constants
     │
     ├── hosts/                 # Host-specific configurations 
     ├── modules/               # Modular configuration system
     ├── lib/                   # Helper functions and utilities
     ├── outputs/               # Flake output orchestration
     ├── vars/                  # Variable definitions
     ├── secrets/               # Agenix encrypted secrets
     ├── scripts/               # Helper scripts
     ├── shells/                # Development shells
     └── templates/             # Project templates
```

## Common Tasks

### Adding a new package

1. Determine which platform this package supports.
    - If the package is darwin only, configure it under `modules/darwin/`.
    - If the package is linux only, configure it under `modules/nixos/`.
    - If the package is available on both platforms, configure it under `modules/shared/`.
2. If the package requires configuration, create a new module in the appropriate directory. Otherwise, find an existing category module and add the package there. 
3. If a new module is created, enable it in the relevant parent module if exists. E.g., after adding a new `dotnix.apps.opencode` module, enable it in `dotnix.suits.development`.
4. **Use `dotnix.hm.packages`** to add packages — never use `environment.systemPackages` directly in shared app modules.
5. **Prefer `pkgs-unstable`** over `pkgs` for package sources.
6. For macOS GUI apps, also add the homebrew cask via `homebrew = lib.optionalAttrs pkgs.stdenv.isDarwin { casks = ["app-name"]; };`.

**Looking up package names:** Do NOT use `nix search` — it is extremely slow and often hangs. Instead, use WebFetch on `https://search.nixos.org/packages?channel=25.11&query=<term>` to find package names.

See `references/package-management.md` for module structure patterns.

### Configuring a program

1. Identify if the program is existing in the configuration.
    - If it exists, is the program has a standalone module or it is configured within another module?
        - If standalone, modify the existing module.
        - If within another module, consider creating a new standalone module for better organization.
    - If it does not exist, create a new module in the appropriate directory based on platform.
2. Follow the module structure patterns in `refrerences/package-management.md` to create or modify the module.

See `references/package-management.md` for module structure patterns.

### Adding a new secret

Edit the secret describe file: `secrets/secrets.nix`, adds the new secret file to the list, then create the secret file in `secrets/` with `.age` extension.

```nix
# new secret age file
"secret-file.age".publicKeys = mkSecrets (hostServers ++ desktops);
```

Create a new empty secret file: (Run the bash command under the `dotnix/secrets/` directory)

```bash
echo "" | agenix -e <path-to-secret-file> -i /etc/ssh/ssh_host_ed25519_key
```

Adds the secret file to the `modules/shared/secrets.nix`, append the secret to the `age.secrets` list.

```nix
age.secrets = {
      ...
      "secret-file" = ageSecret {
          file = "secret-file.age";
          owner = user.name;
      }
};
```

### Using flake inputs in modules

The `inputs` specialArg is available in all modules (injected by `mkSystem.nix`):

```nix
{
  inputs,
  ...
}: let
  hm-dag = inputs.home-manager.lib.hm.dag;
in { }
```

### Home Manager activation scripts

For post-deploy actions (git clone, build steps), use `home.activation` with hm-dag:

```nix
home-manager = dotnix-utils.hm.hmConfig {
  home.activation.setup-foo = hm-dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD git clone ... "''${homeDir}/foo"
  '';
};
```

Access `hm-dag` via `inputs.home-manager.lib.hm.dag`.

