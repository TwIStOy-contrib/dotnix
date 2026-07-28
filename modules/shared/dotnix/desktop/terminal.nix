# Shared configurations for terminal emulators, such as font settings and color schemes.
{
  config,
  lib,
  ...
}: let
  cfg = config.dotnix.desktop.terminal;
  contains-nerd-icons = name: (lib.strings.hasInfix "NF" name) || (lib.strings.hasInfix "Nerd Font Mono" name);
in {
  options.dotnix.desktop.terminal = {
    enable = lib.mkEnableOption "Enable module dotnix.desktop.terminal";

    font-family = lib.mkOption {
      type = lib.types.str;
      default = "MonoLisa";
      example = "MonoLisa";
      description = ''
        The font family to use in the terminal.
      '';
    };

    font-variants = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [
        "MonoLisa-Bold"
        "MonoLisa-BoldItalic"
        "MonoLisa-Regular"
        "MonoLisa-RegularItalic"
        "MonoLisaBlack-Regular"
        "MonoLisaBlack-Italic"
        "MonoLisaExtraBold-Regular"
        "MonoLisaExtraBold-Italic"
        "MonoLisaExtraLight-Regular"
        "MonoLisaExtraLight-Italic"
        "MonoLisaLight-Regular"
        "MonoLisaLight-Italic"
        "MonoLisaMedium-Regular"
        "MonoLisaMedium-Italic"
        "MonoLisaSemiBold-Regular"
        "MonoLisaSemiBold-Italic"
        "MonoLisaThin-Regular"
        "MonoLisaThin-Italic"
        "MonoLisaVariableRegular-Black"
        "MonoLisaVariableRegular-Black"
        "MonoLisaVariableItalic-Black"
        "MonoLisaVariableItalic-Black"
        "MonoLisaVariableRegular-Bold"
        "MonoLisaVariableRegular-Bold"
        "MonoLisaVariableItalic-Bold"
        "MonoLisaVariableItalic-Bold"
        "MonoLisaVariableRegular-ExtraBold"
        "MonoLisaVariableRegular-ExtraBold"
        "MonoLisaVariableItalic-ExtraBold"
        "MonoLisaVariableItalic-ExtraBold"
        "MonoLisaVariableRegular-ExtraLight"
        "MonoLisaVariableRegular-ExtraLight"
        "MonoLisaVariableItalic-ExtraLight"
        "MonoLisaVariableItalic-ExtraLight"
        "MonoLisaVariable-Italic"
        "MonoLisaVariable-Italic"
        "MonoLisaVariableRegular-Light"
        "MonoLisaVariableRegular-Light"
        "MonoLisaVariableItalic-Light"
        "MonoLisaVariableItalic-Light"
        "MonoLisaVariableRegular-Medium"
        "MonoLisaVariableRegular-Medium"
        "MonoLisaVariableItalic-Medium"
        "MonoLisaVariableItalic-Medium"
        "MonoLisaVariable-Regular"
        "MonoLisaVariable-Regular"
        "MonoLisaVariableRegular-SemiBold"
        "MonoLisaVariableRegular-SemiBold"
        "MonoLisaVariableItalic-SemiBold"
        "MonoLisaVariableItalic-SemiBold"
        "MonoLisaVariableRegular-Thin"
        "MonoLisaVariableRegular-Thin"
        "MonoLisaVariableItalic-Thin"
        "MonoLisaVariableItalic-Thin"
      ];
      description = ''
        All variants of the font family to use in the terminal. Only kitty uses this.
      '';
    };

    font-size = lib.mkOption {
      type = lib.types.int;
      default = 14;
      example = 14;
      description = ''
        The font size to use in the terminal.
      '';
    };

    font-features = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [
        "-calt"
        "+ss01"
        "+ss07"
        "+ss09"
        "+ss11"
        "+ss16"
        "+ss18"
      ];
      description = ''
        The font features to use in the terminal.
      '';
    };

    theme = {
      dark = lib.mkOption {
        type = lib.types.str;
        default = "catppuccin-mocha";
        example = "catppuccin-mocha";
        description = ''
          The theme to use in the terminal when the system is in dark mode.
        '';
      };

      light = lib.mkOption {
        type = lib.types.str;
        default = "catppuccin-latte";
        example = "catppuccin-latte";
        description = ''
          The theme to use in the terminal when the system is in light mode.
        '';
      };
    };

    map-nerdfont-ranges = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to map Nerd Font icon ranges.
      '';
    };

    shell = lib.mkOption {
      type = lib.types.str;
      default = "/run/current-system/sw/bin/fish --login";
      example = "fish";
      description = ''
        The shell to use in the terminal.
      '';
    };

    nerdfont-family = lib.mkOption {
      type = lib.types.str;
      default = "Symbols Nerd Font Mono";
      example = "Symbols Nerd Font Mono";
      description = ''
        The Nerd Font family to use for icons.
      '';
    };

    adjust-cell-width = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "90%";
      description = ''
        The percentage by which to adjust the cell width.
      '';
    };

    adjust-cell-height = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "90%";
      description = ''
        The percentage by which to adjust the cell height.
      '';
    };
  };
}
