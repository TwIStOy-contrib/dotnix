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
        config = {
          pager = "less -FR";
          # bat natively picks between theme-dark/theme-light by querying the
          # terminal's background color (OSC 11) on every invocation.
          theme = "auto";
          theme-dark = "catppuccin-mocha";
          theme-light = "catppuccin-latte";
          map-syntax = [
            "**/flake.lock:JSON"
          ];
        };
        themes = let
          rev = "d2bbee4f7e7d5bac63c054e4d8eca57954b31471";
        in {
          catppuccin-mocha = {
            src = builtins.fetchurl {
              name = "bat-theme-catppuccin-mocha";
              url = "https://raw.githubusercontent.com/catppuccin/bat/${rev}/themes/Catppuccin%20Mocha.tmTheme";
              sha256 = "sha256:0jrpfd06hviw82xl74m3favq58a586wa7h1qymakx14l8zla26sh";
            };
          };
          catppuccin-latte = {
            src = builtins.fetchurl {
              name = "bat-theme-catppuccin-latte";
              url = "https://raw.githubusercontent.com/catppuccin/bat/${rev}/themes/Catppuccin%20Latte.tmTheme";
              sha256 = "sha256-nTJYvQuXw8XnioTJqJmAsg8MMYJKiFEHKKCcTEtZHsc=";
            };
          };
        };
      };
    };
  };
}
