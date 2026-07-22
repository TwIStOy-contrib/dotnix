{
  config,
  lib,
  dotnix-utils,
  pkgs-unstable,
  ...
}: let
  cfg = config.dotnix.apps.yazi;

  # File name globs that yazi opens with the `text` (nvim) opener.
  # yazi v25.12.29 (#3034) renamed the `name` matcher to `url` to support the
  # virtual file system, so each rule must use `url`, not `name`.
  nvimOpenerFiles = [
    "*.json"
    "*.cpp"
    "*.lua"
    "*.toml"
    "*.yaml"
    "*.c"
    "*.rs"
    "*.ts"
    "*.nix"
    "justfile"
    "LICENSE"
    "flake.lock"
  ];
  nvimRules =
    map (file: {
      url = file;
      use = "text";
    })
    nvimOpenerFiles;
in {
  options.dotnix.apps.yazi = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.yazi";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.yazi = {
        enable = true;
        package = pkgs-unstable.yazi;
        enableBashIntegration = true;
        enableFishIntegration = true;

        # ~/.config/yazi/yazi.toml
        settings = {
          log.enabled = true;
          opener.text = [
            {
              run = "nvim \"$@\"";
              block = true;
            }
          ];
          open.rules = nvimRules;
        };

        # ~/.config/yazi/keymap.toml — yazi reads keymaps from a dedicated file
        # (not yazi.toml), and the manager section was renamed `[manager]` ->
        # `[mgr]` (#2803). `prepend_keymap` layers on top of the defaults.
        keymap.mgr.prepend_keymap = [
          {
            on = "l";
            run = "plugin smart-enter";
            desc = "Enter the child directory, or open the file";
          }
        ];

        # Vendored plugin + init.lua wired through home-manager's native
        # options. The plugin entry file MUST be `main.lua` — the loader
        # defaults to entry "main", not "init".
        plugins.smart-enter = ./plugins/smart-enter.yazi;
        initLua = ./init.lua;
      };
    };
  };
}
