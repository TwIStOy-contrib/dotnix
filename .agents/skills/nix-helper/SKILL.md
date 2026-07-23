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
3. **Verify against the installed binary, not just upstream docs.** Packages from `pkgs-unstable` are often newer than the upstream docs site — when a program rejects its generated config on startup, check the installed `<bin> --version`, then cross-reference the upstream **CHANGELOG** / source for that version (the docs site may still show pre-breaking-change syntax). See `references/package-management.md` → "Validating a generated config" and "Finding the home-manager module API".

See `references/package-management.md` for module structure patterns.

### Adding a new secret

**Runtime path:** Decrypted agenix secrets are available at `/run/agenix/<secret-name>`. Use this path in scripts, justfile recipes, and `writeShellScriptBin` wrappers:

```bash
# Example: reading a secret in a justfile recipe
@export MY_TOKEN="$(cat /run/agenix/my-token)" && some-command
```

Adding a new secret requires **3 files** to be updated/created, in this order:

#### Step 1: Access control — `secrets/secrets.nix`

Add the new `.age` file to the public keys list. This defines **which hosts can decrypt** the secret:

```nix
# Append to the attribute set in secrets/secrets.nix
"my-secret.age".publicKeys = mkSecrets (homeServers ++ desktops);
```

- `homeServers` = `[ poi taihou ]` (NixOS hosts)
- `desktops` = `[ yukikaze yamato LCNDWWYVTFMFX ]` (macOS hosts)
- `mkSecrets` adds the user keys on top of the host list
- Adjust the host groups if the secret should only be available on specific hosts

#### Step 2: Create the encrypted `.age` file — `secrets/<name>.age`

Run `agenix` **from the `secrets/` directory** (it reads `./secrets.nix` relative to cwd):

```bash
cd secrets
echo "" | agenix -e my-secret.age
```

This opens `$EDITOR` with the plaintext. For an empty secret, pipe empty content. If you need to pre-fill a value, set `EDITOR` appropriately:

```bash
# Pre-fill a value
echo "my-secret-value" | EDITOR="cp /dev/stdin" agenix -e my-secret.age
```

#### Step 3: Wire into the system — `modules/shared/secrets.nix`

Add the secret to the `age.secrets` attribute set so agenix decrypts it to `/run/agenix/<name>` at activation:

```nix
age.secrets = {
  # ... existing secrets ...

  my-secret = ageSecret {
    file = "my-secret.age";
    owner = user.name;
  };
};
```

The `ageSecret` helper sets defaults (`owner = "root"`, `mode = "400"`). Override as needed:

```nix
# Custom owner and mode
my-secret = ageSecret {
  file = "my-secret.age";
  owner = user.name;  # non-root owner
  mode = "600";       # custom permissions
};

# Custom decrypt path (e.g., into home directory)
my-secret = (ageSecret {
  file = "my-secret.age";
  owner = user.name;
}) // {
  path = "/home/user/.config/my-secret.conf";
};
```

#### Quick checklist

| # | File | Action |
|---|------|--------|
| 1 | `secrets/secrets.nix` | Add `"<name>.age".publicKeys = mkSecrets (...)` |
| 2 | `secrets/<name>.age` | Create encrypted file (`cd secrets && agenix -e <name>.age`) |
| 3 | `modules/shared/secrets.nix` | Add to `age.secrets` with `ageSecret { }` |

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

### Flake input gotchas

- **Tarball failures**: When `github:` URLs fail with "Truncated tar archive", use `git+https://github.com/OWNER/REPO?shallow=1` instead.
- **Non-existent input overrides**: Check which inputs a flake actually exposes before adding `X.follows = "Y"`. Nix warns but continues for overrides of non-existent inputs.
- **Adding flake inputs for packages**: Use `inputs.FLAKE.packages.${pkgs.system}.default` to reference packages from flake inputs in modules.

### Wrapper pattern for CLI tools needing agenix secrets

When a CLI tool needs a secret at runtime, wrap it with `writeShellScriptBin`:

```nix
secretPath = config.age.secrets."my-secret".path;
myTool = pkgs.writeShellScriptBin "my-tool" ''
  export MY_API_KEY="$(cat ${secretPath})"
  exec ${myToolPkg}/bin/my-tool "$@"
'';
```

Do NOT use `home.sessionVariables` for `$(cat ...)` — it doesn't support shell expansion.

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

