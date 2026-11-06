# Rex (https://superlogical.com/rex) GUI preferences, written to the
# com.superlogical.rex UserDefaults domain, GUI shortcut overrides in
# Application Support, plus the init.lua for the app's local bundled
# server (run-mode=bundled, socket in
# ~/Library/Application Support/rex/server.sock).
#
# The app itself is installed manually (Rex Beta.app, no homebrew cask).
#
# App-owned keys must NOT be declared, or activation fights the app:
# RexSync.servers, Workspace.lastFocusedSession, Workspace.programActivitySeen,
# rex.local-server.cached-route.v1, rex.sync.hosts-migrated.v1,
# Workspace.tabIconCount, rex.server.* (local bundled-server state),
# NSWindow Frame*, NSStatusItem*, Onboarding.*, SU* (Sparkle updater).
{
  config,
  lib,
  pkgs,
  dotnix-constants,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.rex;
  terminal = config.dotnix.desktop.terminal;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;
  rexAppSupportDir = "Library/Application Support/com.superlogical.rex";
  # Rendered asset paths and install dir, shared with the NixOS server module
  # so init.lua is substituted the same way on both platforms. The HM profile
  # bin dir is an absolute path for Rex-launched commands, because the bundled
  # server's PATH may lack the HM profile.
  rexPaths = config.dotnix.rex.substitutions;
  rexFiles = config.dotnix.rex.files;
  # The app-bundled CLI (Versions/Current is an app-maintained symlink);
  # darwin has no HM-profile rex.
  rexBin = "${homeDir}/${rexAppSupportDir}/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex";
  rexServer = "unix://${homeDir}/Library/Application%20Support/rex/server.sock";
in {
  options.dotnix.apps.rex = {
    enable = lib.mkEnableOption "Rex terminal GUI preferences";

    fontFitOnFocus = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Remember the display's font size on native-window focus and fit the active Rex pane on selection changes, using Hammerspoon.";
    };

    fontFitHotkey = lib.mkOption {
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          modifiers = lib.mkOption {
            type = lib.types.listOf (lib.types.enum ["cmd" "alt" "ctrl" "shift"]);
            default = ["cmd" "alt" "shift"];
          };
          key = lib.mkOption {
            type = lib.types.str;
            default = "F";
          };
        };
      });
      default = {};
      description = "Hammerspoon shortcut for fitting all visible Rex panes; active only while Rex is focused.";
    };

    dark-theme = lib.mkOption {
      type = lib.types.str;
      default = "ink-meridian";
      description = ''
        Theme ID used when the system is in dark mode.
      '';
    };

    light-theme = lib.mkOption {
      type = lib.types.str;
      default = "porcelain-morning";
      description = ''
        Theme ID used when the system is in light mode.
      '';
    };

    pane-density = lib.mkOption {
      type = lib.types.str;
      default = "comfortable";
      description = ''
        Spacing of panes in the workspace. One of the densities offered by
        the Rex settings UI (e.g. comfortable, compact).
      '';
    };

    tab-style = lib.mkOption {
      type = lib.types.str;
      default = "horizontal";
      description = ''
        Tab bar style (e.g. horizontal, vertical).
      '';
    };

    sidebar-position = lib.mkOption {
      type = lib.types.str;
      default = "left";
      description = ''
        Which side the sidebar sits on (left, right).
      '';
    };

    extra-settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = ''
        Extra com.superlogical.rex defaults merged over the managed set.
        Use for keys this module does not model. Don't put app-owned keys
        here (see the note at the top of this file).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.apps.hammerspoon = lib.mkIf (cfg.fontFitOnFocus || cfg.fontFitHotkey != null) {
      enable = true;
      extraConfig = ''
        rexFontFit = dofile(${builtins.toJSON "${rexPaths.hmConfigDir}/rex/focus-font-fit.lua"}).start({
          rex = ${builtins.toJSON rexBin},
          server = ${builtins.toJSON rexServer},
          script = ${builtins.toJSON "${rexPaths.hmConfigDir}/rex/font-fit.lua"},
          onFocus = ${lib.boolToString cfg.fontFitOnFocus},
          hotkey = ${
          if cfg.fontFitHotkey == null
          then "nil"
          else ''{modifiers = {${lib.concatMapStringsSep ", " builtins.toJSON cfg.fontFitHotkey.modifiers}}, key = ${builtins.toJSON cfg.fontFitHotkey.key}}''
        },
        })
      '';
    };

    dotnix.hm.packages = [
      (pkgs.writeShellScriptBin "rex-font-fit" ''
        exec ${lib.escapeShellArg rexBin} do ${lib.escapeShellArg "${rexPaths.hmConfigDir}/rex/font-fit.lua"} "$@"
      '')
    ];

    # Font family/size follow dotnix.desktop.terminal so Rex stays in sync
    # with ghostty/kitty/neovide. The family string must match the installed
    # font's family name exactly (modules/darwin/font.nix installs it).
    system.defaults.CustomUserPreferences."com.superlogical.rex" =
      {
        "Workspace.terminalFontName" = terminal.font-family;
        "Workspace.terminalFontPointSize" = terminal.font-size;
        "Workspace.terminalFontSmoothing" = true;
        "Workspace.terminalCursorStyle" = "block";
        "Workspace.darkThemeID" = cfg.dark-theme;
        "Workspace.lightThemeID" = cfg.light-theme;
        "Workspace.paneDensity" = cfg.pane-density;
        "Workspace.tabStyle" = cfg.tab-style;
        "Workspace.sidebarPosition" = cfg.sidebar-position;
        "Workspace.terminalCopyOnSelect" = false;
        "Workspace.terminalCopyAnimation" = true;
        "Workspace.terminalUsesDisplayP3" = true;
        "Workspace.terminalSmoothScrolling" = true;
        "Workspace.terminalFallbackFontNames" = ["icomoon"];
        "Workspace.terminalStartupCommand" = "${rexPaths.hmProfileBin}/fish";
        "Workspace.inactivePaneFadeMode" = "both";
        "Workspace.usesStandardInactiveWindowPaneStyles" = true;
        "Workspace.tabIconTintMode" = "off";
        "Workspace.notificationPosition" = "bottom-right";
        "rex.client.remoteControl" = true;
      }
      // cfg.extra-settings;

    # init.lua + helper scripts for the local bundled server (read from
    # ~/.config/rex/; the app sets REX_SERVER to the local socket). Same
    # shared files as taihou's system server, so local sessions get the
    # same actions and bindings. Apply after activation with
    # `rex config check && rex config reload`.
    dotnix.rex.substitutions = {
      inherit rexBin rexServer;
    };

    home-manager = dotnix-utils.hm.hmConfig {
      home.file."${rexAppSupportDir}/Shortcuts/shortcuts.json" = {
        # Replace the GUI-written file when first adopting it into Nix.
        force = true;
        text = builtins.toJSON {
          version = 1;
          migrations = ["bracket-characters"];
          layer = {
            name = "settings";
            bindings = [
              {
                action = "client.tab.new";
                keys = ["cmd+n"];
                source = "settings";
              }
            ];
            removals = [
              {
                action = "client.window.new";
                keys = ["cmd+n"];
              }
            ];
          };
        };
      };

      xdg.configFile."rex/init.lua" = {
        text = rexFiles."init.lua";
        force = true;
      };
      xdg.configFile."rex/actions/init.lua".text = rexFiles."actions/init.lua";
      xdg.configFile."rex/font-fit.lua".text = rexFiles."font-fit.lua";
      xdg.configFile."rex/display-info.js".text = rexFiles."display-info.js";
      xdg.configFile."rex/focus-font-fit.lua".text = rexFiles."focus-font-fit.lua";
    };
  };
}
