{
  config,
  lib,
  pkgs,
  dotnix-constants,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.desktop.ghostty;
  termCfg = config.dotnix.desktop.terminal;

  toConfigItem = key: value: {
    "${key}" = value;
  };

  font-features = builtins.concatStringsSep ", " termCfg.font-features;

  capitalize = c:
    if c == ""
    then ""
    else builtins.substring 0 1 (lib.toUpper c) + builtins.substring 1 (builtins.stringLength c - 1) c;

  theme = lib.strings.concatStringsSep " " (builtins.map capitalize (lib.strings.splitString "-" termCfg.theme));

  simpleSettings =
    {
      inherit (termCfg) font-family font-size;
      inherit theme;
      font-feature = font-features;
      working-directory = "home";
      clipboard-read = "allow";
      clipboard-write = "allow";
      copy-on-select = "clipboard";

      quick-terminal-position = "bottom";
      quick-terminal-screen = "main";
      quick-terminal-animation-duration = "0.5";
      quick-terminal-autohide = "false";

      macos-titlebar-style = "transparent";
      macos-titlebar-proxy-icon = "hidden";
      macos-option-as-alt = "true";
      macos-auto-secure-input = "false";

      font-thicken = "true";
      background-opacity = "0.9";
      background-blur = "20";

      window-title-font-family = "Maple Mono NF CN";

      # custom-shader = "ghostty-shader-playground/shaders/cursor_frozen.glsl";

      auto-update-channel = "tip";
      cursor-click-to-move = "true";
      shell-integration-features = "ssh-env,ssh-terminfo";
    }
    // (
      if termCfg.adjust-cell-width != ""
      then {
        inherit (termCfg) adjust-cell-width;
      }
      else {}
    )
    // (
      if termCfg.adjust-cell-height != ""
      then {
        inherit (termCfg) adjust-cell-height;
      }
      else {}
    );

  keybindings = {
    "cmd+r" = "reload_config";
    "cmd+equal" = "increase_font_size:1";
    "cmd+minus" = "decrease_font_size:1";
    "cmd+backspace" = "reset_font_size";
    "cmd+v" = "paste_from_clipboard";
    "cmd+a" = "select_all";
    "cmd+n" = "new_tab";
    "cmd+shift+left_bracket" = "previous_tab";
    "cmd+shift+right_bracket" = "next_tab";
    "cmd+1" = "goto_tab:1";
    "cmd+2" = "goto_tab:2";
    "cmd+3" = "goto_tab:3";
    "cmd+4" = "goto_tab:4";
    "cmd+5" = "goto_tab:5";
    "cmd+6" = "goto_tab:6";
    "cmd+7" = "goto_tab:7";
    "cmd+8" = "goto_tab:8";
    "cmd+9" = "goto_tab:9";
    "cmd+d" = "new_split:right";
    "cmd+shift+d" = "new_split:down";
    "cmd+h" = "goto_split:left";
    "cmd+j" = "goto_split:bottom";
    "cmd+k" = "goto_split:top";
    "cmd+l" = "goto_split:right";
    "cmd+p" = "toggle_split_zoom";
    "cmd+left_bracket" = "goto_split:previous";
    "cmd+right_bracket" = "goto_split:next";
  };

  settings =
    (
      lib.attrsets.mapAttrsToList (key: value: toConfigItem key value) simpleSettings
    )
    ++ (
      builtins.map (feature: {font-feature = feature;}) termCfg.font-features
    )
    ++ (
      lib.attrsets.mapAttrsToList (key: value: toConfigItem "keybind" "${key}=${value}") keybindings
    );

  generateConfigLine = attrs: lib.attrsets.mapAttrsToList (key: value: "${key} = ${toString value}") attrs;
in {
  options.dotnix.desktop.ghostty = {
    enable = lib.mkEnableOption "Enable module dotnix.desktop.ghostty";

    only-connect-dev-server = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Which server to connect to when opening a new terminal. If set, it will connect to the dev server via SSH.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      xdg.configFile = let
        configLines = builtins.map generateConfigLine (
          settings
          ++ (
            if cfg.only-connect-dev-server != ""
            then [
              {
                command = "ssh ${cfg.only-connect-dev-server}";
              }
            ]
            else [
              {
                command = termCfg.shell;
              }
            ]
          )
        );
        # concat lines
        configContent = lib.concatStringsSep "\n" (
          builtins.foldl' (x: y: x ++ y) [] configLines
        );
      in {
        "ghostty/config" = {
          source = pkgs.writeText "config" ''
            ${configContent}
          '';
          force = true;
        };
        "ghostty/ghostty-shader-playground" = {
          source = pkgs.fetchFromGitHub {
            # https://github.com/KroneCorylus/ghostty-shader-playground.git
            owner = "KroneCorylus";
            repo = "ghostty-shader-playground";
            rev = "b539cea7b34cdc883726db018ae09e8e3f862aea";
            sha256 = "sha256-dfk2Ti+T1jEC5M8ijaO1KnfzW6MP5yswovZgoptqO3A=";
          };
        };
      };
    };
  };
}
