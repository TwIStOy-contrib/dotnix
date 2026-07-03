{
  config,
  lib,
  pkgs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.espanso;

  # espanso's config directory on macOS is launch-context dependent:
  #   - LaunchAgent-launched (no XDG_CONFIG_HOME in the plist) -> ~/Library/Application Support/espanso
  #   - shell-launched (XDG_CONFIG_HOME=~/.config)             -> ~/.config/espanso
  # To get deterministic behavior regardless of how the daemon was started,
  # we deploy the SAME file set into both roots.
  espansoRoots = [
    ".config/espanso"
    "Library/Application Support/espanso"
  ];

  # File contents shared by both roots. Keys are paths relative to the
  # espanso config root (no leading slash).
  espansoFiles = {
    "config/default.yml" = {
      # Empty default config profile. espanso requires this file to exist.
      text = "";
    };

    "config/obsidian.yml" = {
      # Obsidian app-specific config: activate the Obsidian-only match file
      # when the focused app's bundle id matches `md.obsidian`.
      # On macOS, `filter_class` matches against the app's bundle id.
      text = ''
        filter_class: "md.obsidian"
        extra_includes:
          - "../match/_obsidian.yml"
      '';
    };

    "match/_obsidian.yml" = {
      # Obsidian-only matches. The leading underscore prevents espanso
      # from auto-loading this file globally; it is only pulled in by
      # config/obsidian.yml via extra_includes.
      text = ''
        matches:
          # Expand :date to today's date as YYYY-MM-DD
          - trigger: ":date"
            replace: "{{today}}"
            vars:
              - name: today
                type: date
                params:
                  format: "%Y-%m-%d"
      '';
    };

    "match/base.yml" = {
      # Overwrite the sample base.yml shipped by the espanso cask.
      # Without this, the installer's example matches (`:espanso`,
      # `:date`, `:shell`) would still be loaded globally.
      text = ''
        # espanso match file
        # Managed by Nix. Add global matches under this file.
        matches: []
      '';
    };
  };

  # Build a home.file attrset by stamping the shared contents under each root.
  espansoHomeFiles = lib.concatMapAttrs (root: filesForRoot:
    lib.mapAttrs' (subPath: f:
      lib.nameValuePair "${root}/${subPath}" {
        enable = true;
        text = f.text;
        force = true;
      })
    filesForRoot) (lib.genAttrs espansoRoots (_: espansoFiles));
in {
  options.dotnix.apps.espanso = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.espanso";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "Espanso is currently configured only for macOS in this module";
      }
    ];

    homebrew = {
      casks = ["espanso"];
    };

    home-manager = dotnix-utils.hm.hmConfig {
      home.file = espansoHomeFiles;
    };
  };
}
