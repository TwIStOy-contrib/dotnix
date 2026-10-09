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

        policies = {
          AutofillAddressEnabled = true;
          AutofillCreditCardEnabled = false;
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DontCheckDefaultBrowser = true;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
        };

        profiles."default" = {
          settings = {
            "intl.locale.requested" = "zh-CN,en-US";
          };
          pinsForce = true;
          pinsForceAction = "remove";
          spaceRouting.force = true;
        };
      };
    };
  };
}
