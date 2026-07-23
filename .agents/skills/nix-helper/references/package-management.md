# Package Management

## New Package Module

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

## Package configuration Patterns

### Standalone Package (no HM program module)

Use `dotnix.hm.packages` with `pkgs-unstable` for packages that don't have a dedicated home-manager program module:

```nix
{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  cfg = config.dotnix.apps.todoist;
in {
  options.dotnix.apps.todoist = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.todoist";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = with pkgs-unstable; [
      todoist
    ];

    # For macOS GUI apps, also add the homebrew cask
    homebrew = lib.optionalAttrs pkgs.stdenv.isDarwin {
      casks = ["todoist"];
    };
  };
}
```

### Home Manager Package

For packages that have a dedicated home-manager program module:

```nix
{
  config,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.bat;
in {
  options.dotnix.apps.bat = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.bat";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.bat = {
        enable = true;
        # configuration options...
      };
    };
  };
}
```

### Package from Flake Input

For packages not in nixpkgs but available as a flake:

```nix
{
  config,
  lib,
  pkgs,
  inputs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.myApp;
  myApp = inputs.my-app-flake.packages.${pkgs.system}.default;
in {
  options.dotnix.apps.myApp = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.myApp";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [ myApp ];
  };
}
```

Add the flake input to `flake.nix` first:
```nix
my-app-flake = {
  url = "github:owner/repo";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

#### Finding the current home-manager program-module API

home-manager's per-program options (e.g. `programs.yazi.{settings,keymap,plugins,initLua,theme,vfs}`) aren't documented centrally — read `modules/programs/<name>.nix` in the [home-manager repo](https://github.com/nix-community/home-manager):

```bash
nix flake clone github:nix-community/home-manager --dest /tmp/hm
sed -n '1,220p' /tmp/hm/modules/programs/yazi.nix   # or whichever program
```

Prefer these native options over hand-rolled `xdg.configFile` — a manual `xdg.configFile."<prog>/init.lua"` (or similar) collides with the native option if both produce the file.

### Xdg-Based Configuration

```nix
{
  config,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.exampleApp;
in {
  options.dotnix.apps.exampleApp = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.exampleApp";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."exampleApp/config.toml".text = ''
    # configuration content...
    '';
  };
};
```

### Configuration file location other than XDG

```nix
{
  config,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.anotherApp;
in {
  options.dotnix.apps.anotherApp = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.anotherApp";
  };

  config = lib.mkIf cfg.enable {
    home.file.".anotherApp/config.yaml".text = ''
    # configuration content...
    '';
  };
};
```

## Validating a generated config without deploying

Most CLI tools parse their config on startup — even for `--version`. To check a generated config against the real installed binary without a full `just` deploy, materialize the expected output into a temp `XDG_CONFIG_HOME` and run a non-interactive command that still parses config:

```bash
T=/tmp/cfgtest && rm -rf "$T" && mkdir -p "$T/<prog>"
# write the TOML/YAML the Nix `settings` would generate into "$T/<prog>/"
XDG_CONFIG_HOME="$T" <prog> --version    # clean version string == config valid
```

This catches schema drift (renamed keys, moved sections) the moment a `pkgs-unstable` bump lands, instead of after deploy. For programs whose `--version` doesn't parse config, look for a `--check` / `--validate` subcommand.

Do NOT drive an interactive TUI through `script`/pty for validation — it hangs on the session. Use a non-interactive command that still parses the config.
