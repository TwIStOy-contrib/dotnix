{
  config,
  lib,
  pkgs,
  inputs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.desktop.zen;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in {
  imports = dotnix-utils.path.listModules ./.;

  options.dotnix.desktop.zen = {
    enable = lib.mkEnableOption "Zen Browser";
  };

  config = lib.mkIf cfg.enable {
    homebrew = lib.optionalAttrs isDarwin {
      casks = ["zen"];
    };

    home-manager = dotnix-utils.hm.hmConfig {
      imports = [inputs.zen-browser.homeModules.beta];

      programs.zen-browser = {
        enable = true;
        # Homebrew owns the macOS app; Home Manager still manages its profiles.
        package = lib.mkIf isDarwin null;

        profiles.default = {
          id = 0;
          isDefault = true;
          settings = {};
          userChrome = "";
          userContent = "";
        };
      };
    };
  };
}
