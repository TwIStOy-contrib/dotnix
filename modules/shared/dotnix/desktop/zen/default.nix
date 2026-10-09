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
          ExtensionSettings = {
            # 1Password
            "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
            };
            # Tampermonkey
            "firefox@tampermonkey.net" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi";
            };
            # Vimium
            "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
            };
            # Refined GitHub
            "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/refined-github-/latest.xpi";
            };
          };
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
            "browser.translations.automaticallyPopup" = false;
            "browser.translations.neverTranslateLanguages" = "en";
          };
          pinsForce = true;
          pinsForceAction = "remove";
          spaceRouting.force = true;
        };
      };
    };
  };
}
