# Vendored frp module (from TwIStOy/nur-packages, originally derived from
# nixpkgs' services/networking/frp.nix). Kept locally because it adds a
# `configFile` option: upstream only supports `settings`, which is rendered
# into a world-readable store file, while `configFile` lets hosts point frpc
# at an agenix-managed secret under /etc (server address + auth token must
# not enter the store).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.frp;
  settingsFormat = pkgs.formats.toml {};
  generatedConfigFile = settingsFormat.generate "frp.toml" cfg.settings;
  isClient = cfg.role == "client";
  isServer = cfg.role == "server";
in {
  # Same `services.frp` namespace as the stock module plus one extra option,
  # so the stock module must not be loaded alongside this one.
  disabledModules = ["services/networking/frp.nix"];

  options.services.frp = {
    enable = lib.mkEnableOption "frp";

    package = lib.mkPackageOption pkgs "frp" {};

    role = lib.mkOption {
      type = lib.types.enum ["server" "client"];
      description = ''
        The frp consists of `client` and `server`. The server is usually
        deployed on the machine with a public IP address, and the client
        is usually deployed on the machine where the Intranet service
        to be penetrated resides.
      '';
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = {};
      description = ''
        Frp configuration, for configuration options see the example of
        [client](https://github.com/fatedier/frp/blob/dev/conf/frpc_full_example.toml)
        or [server](https://github.com/fatedier/frp/blob/dev/conf/frps_full_example.toml)
        on github.
      '';
      example = {
        serverAddr = "x.x.x.x";
        serverPort = 7000;
      };
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      default = generatedConfigFile;
      defaultText = lib.literalExpression ''
        settingsFormat.generate "frp.toml" config.services.frp.settings
      '';
      description = ''
        Path to the frp TOML config file. Prefer this over `settings` when
        the config contains secrets (e.g. an agenix symlink under /etc).
      '';
    };
  };

  config = let
    serviceCapability = lib.optionals isServer ["CAP_NET_BIND_SERVICE"];
    executableFile =
      if isClient
      then "frpc"
      else "frps";
  in
    lib.mkIf cfg.enable {
      systemd.services.frp = {
        wants = lib.optionals isClient ["network-online.target"];
        after =
          if isClient
          then ["network-online.target"]
          else ["network.target"];
        wantedBy = ["multi-user.target"];
        description = "A fast reverse proxy frp ${cfg.role}";
        serviceConfig =
          {
            Type = "simple";
            Restart = "on-failure";
            RestartSec = 15;
            ExecStart = "${cfg.package}/bin/${executableFile} --strict_config -c ${cfg.configFile}";
            DynamicUser = true;
            # Hardening
            CapabilityBoundingSet = serviceCapability;
            AmbientCapabilities = serviceCapability;
            PrivateDevices = true;
            ProtectHostname = true;
            ProtectClock = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectKernelLogs = true;
            ProtectControlGroups = true;
            RestrictAddressFamilies =
              ["AF_INET" "AF_INET6"]
              ++ lib.optionals isClient ["AF_UNIX"];
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            PrivateMounts = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = ["@system-service"];
          }
          // lib.optionalAttrs isServer {
            StateDirectory = "frp";
            StateDirectoryMode = "0700";
            UMask = "0007";
          };
      };
    };
}
