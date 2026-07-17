{
  config,
  lib,
  pkgs-unstable,
  inputs,
  ...
}: let
  cfg = config.dotnix.services.mihomo;

  # The stable nixpkgs this flake builds against (nixos-25.11) ships an older
  # `services.mihomo` that lacks `tunMode` / `processesInfo`. Pull the newer
  # module from the unstable nixpkgs input so we get the full option set, and
  # resolve the binary from the same source to keep module + package in sync.
  nixos-unstable = inputs.nixpkgs-unstable;
  unstableMihomoModule = "${nixos-unstable}/nixos/modules/services/networking/mihomo.nix";
in {
  # Replace the stable mihomo module with the unstable one.
  disabledModules = ["services/networking/mihomo.nix"];
  imports = [unstableMihomoModule];

  options.dotnix.services.mihomo = {
    enable = lib.mkEnableOption "mihomo (Clash.Meta core) proxy on this host.";

    mixedPort = lib.mkOption {
      type = lib.types.port;
      default = 7893;
      description = ''
        Local HTTP/SOCKS mixed proxy port. Point applications (or
        `networking.proxy`) here.
      '';
    };

    controllerPort = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = ''
        Port for mihomo's RESTful `external-controller` and the bundled
        metacubexd web UI. Opened in the firewall.
      '';
    };

    tunMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Grant `CAP_NET_ADMIN` and enable TUN mode support in mihomo's systemd
        unit. TUN itself must still be enabled in the mihomo config. Off by
        default — leave disabled for a plain mixed-port proxy.
      '';
    };

    processesInfo = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Grant capabilities so `process-name` based rules work.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.mihomo = {
      enable = true;
      inherit (cfg) tunMode processesInfo;
      # The config (subscription url/token + web UI secret) lives in the
      # `mihomo-config` agenix secret and is never placed in the nix store.
      configFile = config.age.secrets."mihomo-config".path;
      # Resolve mihomo + webui from unstable to match the unstable module.
      package = lib.mkDefault nixos-unstable.legacyPackages.${pkgs-unstable.system}.mihomo;
      webui = lib.mkDefault nixos-unstable.legacyPackages.${pkgs-unstable.system}.metacubexd;
    };

    networking.firewall.allowedTCPPorts = [cfg.controllerPort];
  };
}
