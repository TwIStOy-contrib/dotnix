{
  config,
  lib,
  pkgs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.espanso;

  yamlFormat = pkgs.formats.yaml {};

  # Native date match: `offset` is in seconds (espanso 2.3+), e.g. 86400
  # shifts by one day.
  dateMatch = trigger: offset: {
    inherit trigger;
    replace = "{{date}}";
    vars = [
      {
        name = "date";
        type = "date";
        params =
          {
            format = "%Y-%m-%d";
          }
          // (lib.optionalAttrs (offset != 0) {inherit offset;});
      }
    ];
  };

  # Weekday-of-current-week match (ISO week, Monday first): weekday 0 is
  # Monday, 4 is Friday. BSD date cannot express "Monday of this week",
  # so compute it with the system python3.
  weekdayMatch = name: weekday: {
    trigger = ":${name}";
    replace = "{{date}}";
    vars = [
      {
        name = "date";
        type = "script";
        params.args = [
          "/usr/bin/python3"
          "-c"
          "import datetime, sys; t = datetime.date.today(); print((t - datetime.timedelta(days=t.weekday()) + datetime.timedelta(days=int(sys.argv[1]))).isoformat())"
          (toString weekday)
        ];
      }
    ];
  };

  # espanso's config directory on macOS is launch-context dependent:
  #   - LaunchAgent-launched (no XDG_CONFIG_HOME in the plist) -> ~/Library/Application Support/espanso
  #   - shell-launched (XDG_CONFIG_HOME=~/.config)             -> ~/.config/espanso
  # To get deterministic behavior regardless of how the daemon was started,
  # we deploy the SAME file set into both roots.
  espansoRoots = [
    ".config/espanso"
    "Library/Application Support/espanso"
  ];

  # File contents shared by both roots, declared as Nix attribute sets and
  # serialized to YAML. Keys are paths relative to the espanso config root
  # (no leading slash).
  espansoFiles = {
    # Empty default config profile. espanso requires this file to exist.
    "config/default.yml" = {
      yaml = {};
    };

    # Obsidian app-specific config: activate the Obsidian-only match file
    # when the focused app's bundle id matches `md.obsidian`.
    # On macOS, `filter_class` matches against the app's bundle id.
    "config/obsidian.yml" = {
      yaml = {
        filter_class = "md.obsidian";
        extra_includes = ["../match/_obsidian.yml"];
      };
    };

    # Obsidian-only matches. The leading underscore prevents espanso
    # from auto-loading this file globally; it is only pulled in by
    # config/obsidian.yml via extra_includes.
    "match/_obsidian.yml" = {
      yaml = {
        # All triggers expand to dates in %Y-%m-%d format.
        matches =
          [
            # Expand :date to today's date (kept for muscle memory)
            (dateMatch ":date" 0)
            (dateMatch ":today" 0)
            (dateMatch ":tomorrow" 86400)
          ]
          ++ (map (wd: weekdayMatch wd.name wd.index) [
            {
              name = "mon";
              index = 0;
            }
            {
              name = "tue";
              index = 1;
            }
            {
              name = "wed";
              index = 2;
            }
            {
              name = "thu";
              index = 3;
            }
            {
              name = "fri";
              index = 4;
            }
          ]);
      };
    };

    # Overwrite the sample base.yml shipped by the espanso cask.
    # Without this, the installer's example matches (`:espanso`,
    # `:date`, `:shell`) would still be loaded globally.
    # Global matches belong here.
    "match/base.yml" = {
      yaml = {
        matches = [];
      };
    };
  };

  # Build a home.file attrset by stamping the shared contents under each root.
  espansoHomeFiles = lib.concatMapAttrs (root: filesForRoot:
    lib.mapAttrs' (subPath: f:
      lib.nameValuePair "${root}/${subPath}" {
        enable = true;
        source = yamlFormat.generate (baseNameOf subPath) f.yaml;
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
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
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
