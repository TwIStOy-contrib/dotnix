# Rex (https://superlogical.com/rex) GUI preferences, written to the
# com.superlogical.rex UserDefaults domain. Only the client-side
# appearance/behavior keys are declared here; the server-side Lua config
# (~/.config/rex/init.lua) is a separate concern.
#
# The app itself is installed manually (Rex Beta.app, no homebrew cask).
#
# App-owned keys must NOT be declared, or activation fights the app:
# RexSync.servers, Workspace.lastFocusedSession, Workspace.programActivitySeen,
# rex.local-server.cached-route.v1, NSWindow Frame*, NSStatusItem*, Onboarding.*,
# SU* (Sparkle updater).
{
  config,
  lib,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.rex;
  terminal = config.dotnix.desktop.terminal;
in {
  options.dotnix.apps.rex = {
    enable = lib.mkEnableOption "Rex terminal GUI preferences";

    dark-theme = lib.mkOption {
      type = lib.types.str;
      default = "whitby-bay";
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
    # Font family/size follow dotnix.desktop.terminal so Rex stays in sync
    # with ghostty/kitty/neovide. The family string must match the installed
    # font's family name exactly (modules/darwin/font.nix installs it).
    system.defaults.CustomUserPreferences."com.superlogical.rex" =
      {
        "Workspace.terminalFontName" = terminal.font-family;
        "Workspace.terminalFontPointSize" = terminal.font-size;
        "Workspace.terminalFontSmoothing" = false;
        "Workspace.terminalCursorStyle" = "bar";
        "Workspace.darkThemeID" = cfg.dark-theme;
        "Workspace.lightThemeID" = cfg.light-theme;
        "Workspace.paneDensity" = cfg.pane-density;
        "Workspace.tabStyle" = cfg.tab-style;
        "Workspace.sidebarPosition" = cfg.sidebar-position;
        "Workspace.terminalCopyOnSelect" = false;
        "Workspace.terminalCopyAnimation" = true;
        "Workspace.terminalUsesDisplayP3" = false;
        "Workspace.terminalSmoothScrolling" = true;
        "Workspace.terminalFallbackFontNames" = ["icomoon"];
        "Workspace.terminalStartupCommand" = "/etc/profiles/per-user/${dotnix-constants.user.name}/bin/fish";
        "Workspace.inactivePaneFadeMode" = "both";
        "Workspace.usesStandardInactiveWindowPaneStyles" = true;
        "Workspace.tabIconTintMode" = "off";
        "Workspace.notificationPosition" = "top-right";
        "rex.client.remoteControl" = true;
      }
      // cfg.extra-settings;
  };
}
