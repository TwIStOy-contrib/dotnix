{
  config,
  lib,
  pkgs,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.services.moshi;
  moshi-hook = pkgs.callPackage ../apps/moshi-hook/package.nix {};
  # moshi reaches api.getmoshi.app over HTTP, so it honours the usual
  # *_proxy env vars. We inject them explicitly into the unit so the
  # daemon does not depend on the user systemd manager inheriting them
  # (that environment is only refreshed on reboot; on long-uptime hosts
  # a stale user manager keeps serving the old proxy long after
  # networking.proxy.default was bumped via `switch`).
  proxyUrl = config.networking.proxy.default;
  proxyEnv = lib.optionalAttrs (proxyUrl != null) {
    http_proxy = proxyUrl;
    https_proxy = proxyUrl;
    all_proxy = proxyUrl;
    no_proxy = "127.0.0.1,localhost";
  };
in {
  options.dotnix.services.moshi = {
    enable = lib.mkEnableOption "Enable module dotnix.services.moshi";

    package = lib.mkOption {
      type = lib.types.package;
      default = moshi-hook;
      defaultText = lib.literalExpression "moshi-hook";
      description = "Package providing the moshi binary to run serve with.";
    };
  };

  # moshi-hook serve is a per-user daemon: it binds a Unix socket in
  # $XDG_RUNTIME_DIR, reads that user's agent hook configs (~/.codex,
  # ~/.pi, ~/.config/opencode) and writes state to ~/.local/state/mosi.
  # A root system service has none of that, so this must run as the user
  # via home-manager, with lingering enabled so the user manager (and
  # /run/user/<uid>) exists at boot.
  config = lib.mkIf cfg.enable {
    # Start the user systemd manager at boot so the service can run
    # without an active login session.
    users.users.${dotnix-constants.user.name}.linger = true;

    home-manager = dotnix-utils.hm.hmConfig {
      systemd.user.services.moshi = {
        Unit = {
          Description = "Moshi serve daemon";
        };
        Service = {
          ExecStart = "${lib.getExe cfg.package} serve";
          Environment = lib.mapAttrsToList (n: v: "${n}=${v}") proxyEnv;
          # `always` (not `on-failure`): moshi-hook catches SIGTERM and
          # exits 0 on graceful shutdown, which systemd treats as success —
          # `on-failure` would therefore not restart it after a plain `kill`.
          Restart = "always";
          RestartSec = "2s";
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };
    };
  };
}
