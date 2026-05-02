{
  dotnix-utils,
  lib,
  ...
}: let
  inherit (dotnix-utils) enabled;
  hostname = "LCNDWWYVTFMFX";
in {
  dotnix = {
    darwin-shared-suit = enabled;
    darwin.zscaler-ca.enable = true;
    desktop = {
      neovide.extraSettings.font.size = 18;
      terminal = {
        font-size = 18;
        font-family = "Maple Mono NF CN";
        font-variants = builtins.map (variant: "MapleMono-NF-CN-${variant}") [
          "Bold"
          "BoldItalic"
          "ExtraBold"
          "ExtraBoldItalic"
          "ExtraLight"
          "ExtraLightItalic"
          "Italic"
          "Light"
          "LightItalic"
          "Medium"
          "MediumItalic"
          "Regular"
          "SemiBold"
          "SemiBoldItalic"
          "Thin"
          "ThinItalic"
        ];
        font-features = ["+zero" "+ss01" "+ss02" "+ss03" "+ss07" "+ss09" "+ss10" "+cv03" "+cv10" "+cv34" "+cv61"];
        map-nerdfont-ranges = false;
      };

      neovide.createRemoteHostWrappers = [
        "dev.work.local"
      ];
    };

    apps.zed = {
      buffer_font_size = 18;
      ui_font_size = 16;
      ssh_connections = [
        {
          host = "dev.work.local";
          projects = [
          ];
        }
      ];
    };

    services.tailscale = {
      enable = true;
      extraUpFlags = [
        "--advertise-tags=tag:desktop"
        "--accept-routes"
      ];
    };

    development.portal = {
      enable = true;
      service.enable = true;
      tunnels = [
        {
          name = "dev-work";
          host = "dev.work.local";
          mode = "local";
          local = "127.0.0.1:9999";
          remote = "127.0.0.1:2323";
        }
        {
          name = "dev-work-3000";
          host = "dev.work.local";
          mode = "local";
          local = "127.0.0.1:3000";
          remote = "127.0.0.1:3000";
        }
      ];
    };
  };

  homebrew = {
    masApps = lib.mkForce {};
  };

  networking.hostName = hostname;
  networking.computerName = hostname;

  system.defaults.smb.NetBIOSName = hostname;
  system.stateVersion = 5;
}
