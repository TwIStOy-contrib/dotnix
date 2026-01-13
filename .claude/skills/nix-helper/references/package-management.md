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

### Home Manager Package

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
