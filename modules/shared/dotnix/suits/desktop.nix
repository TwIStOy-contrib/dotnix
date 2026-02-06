{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  neovim-pkgs,
  ...
}: let
  cfg = config.dotnix.suits.desktop;
in {
  options.dotnix.suits.desktop = {
    enable = lib.mkEnableOption "Enable desktop suit";
  };

  config = lib.mkIf cfg.enable {
    dotnix.desktop = {
      kitty = {
        enable = true;
      };

      ghostty = {
        enable = true;
      };

      vscodium = {
        enable = false;
      };

      neovide = {
        enable = true;
        package =
          if pkgs.stdenv.isDarwin
          then "homebrew"
          else "unstable";
        skipPackage = true;
        createRemoteHostWrappers = [
          "poi.remote"
          "poi.local"
          "taihou.remote"
          "taihou.local"
        ];
        settings =
          {
            maximized = false;
            srgb = true;
            idle = true;
            neovim-bin = neovim-pkgs.default;
          }
          // (lib.optionalAttrs pkgs.stdenv.isDarwin {
            frame = "transparent";
          });
        extraSettings = {
          font = {
            normal = {family = "Maple Mono NF CN";};
            # bold = "MonaspiceKr Nerd Font Mono";
            # bold_italic = "MonaspiceKr Nerd Font Mono";
            features."Maple Mono NF CN" = [
              "+ss01"
              "+ss02"
            ];
            features."MonoLisa Nerd Font" = [
              "+ss11"
              "+zero"
              "-calt"
              "+ss10"
              "+ss02"
              "+ss17"
              "+ss13"
              "+ss04"
            ];
          };
          vsync = true;
          "box-drawing" = {
            mode = "native";
          };
        };
      };
    };
  };
}
