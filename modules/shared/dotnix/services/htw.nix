{
  config,
  lib,
  pkgs,
  inputs,
  isDarwin,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.services.htw;
  htw = inputs.htw.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.dotnix.services.htw = {
    enable = lib.mkEnableOption "htw agent-sessions daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = htw;
      defaultText = lib.literalExpression "inputs.htw.packages.\${pkgs.stdenv.hostPlatform.system}.default";
      description = "Package providing the htw binary to run the daemon with.";
    };
  };

  # `htw daemon` is a per-user service: producers (agent hooks) and consumers
  # (the `htw agents` dashboard) both run as the login user, and the daemon's
  # config lives in ~/.config/htw. Run it as the user on both platforms:
  # a systemd user service on NixOS (with lingering so it starts at boot),
  # a home-manager launchd agent on macOS. No --port/--bind flags here: the
  # daemon resolves them from the [daemon] table of the config.toml written
  # by dotnix.apps.htw (htw's defaults: 127.0.0.1:7482, loopback-only).
  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.optionalAttrs (!isDarwin) {
      # Start the user systemd manager at boot so the daemon runs without an
      # active login session.
      users.users.${dotnix-constants.user.name}.linger = true;
    })

    {
      home-manager = dotnix-utils.hm.hmConfig (lib.mkMerge [
        (lib.optionalAttrs (!isDarwin) {
          systemd.user.services.htw = {
            Unit = {
              Description = "htw agent-sessions daemon";
            };
            Service = {
              ExecStart = "${lib.getExe cfg.package} daemon";
              # `always` (not `on-failure`): a graceful stop exits 0, which
              # `on-failure` would not restart.
              Restart = "always";
              RestartSec = "2s";
            };
            Install = {
              WantedBy = ["default.target"];
            };
          };
        })

        (lib.optionalAttrs isDarwin {
          launchd.agents.htw = {
            enable = true;
            config = {
              ProgramArguments = [(lib.getExe cfg.package) "daemon"];
              RunAtLoad = true;
              KeepAlive = true;
              StandardOutPath = "/tmp/htw.out.log";
              StandardErrorPath = "/tmp/htw.err.log";
            };
          };
        })
      ]);
    }
  ]);
}
