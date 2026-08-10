{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  isDarwin,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.boring;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;

  boringPkg = pkgs-unstable.boring;
  boringExe = lib.getExe cfg.package;

  # boring resolves its config from $BORING_CONFIG, falling back to
  # ~/.boring.toml on macOS and $XDG_CONFIG_HOME/boring/.boring.toml on
  # Linux. Pin the path explicitly so launchd/systemd services and
  # interactive shells always agree on the same file.
  configFile = "${homeDir}/.config/boring/.boring.toml";

  tunnelType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Tunnel name (required)";
      };
      local = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''Local address. Can be a "$host:$port" or just "$port". Required in local, remote and socks modes.'';
      };
      remote = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''Remote address. Can be a "$host:$port" or just "$port". Required in local, remote and socks-remote modes.'';
      };
      host = lib.mkOption {
        type = lib.types.str;
        description = "SSH host alias (from SSH config) or actual hostname";
      };
      mode = lib.mkOption {
        type = lib.types.enum ["local" "remote" "socks" "socks-remote"];
        default = "local";
        description = "Tunnel mode";
      };
      user = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "SSH user";
      };
      identity = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "SSH identity file path";
      };
      port = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.int lib.types.str);
        default = null;
        description = "SSH port";
      };
      group = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Group assignment for the tunnel";
      };
      keep_alive = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Keep-alive interval in seconds";
      };
    };
  };

  mkTunnel = t:
    {
      inherit (t) name host mode;
    }
    // lib.optionalAttrs (t.local != null) {local = t.local;}
    // lib.optionalAttrs (t.remote != null) {remote = t.remote;}
    // lib.optionalAttrs (t.user != null) {user = t.user;}
    // lib.optionalAttrs (t.identity != null) {identity = t.identity;}
    // lib.optionalAttrs (t.port != null) {port = t.port;}
    // lib.optionalAttrs (t.group != null) {group = t.group;}
    // lib.optionalAttrs (t.keep_alive != null) {keep_alive = t.keep_alive;};

  boringConfig =
    {}
    // lib.optionalAttrs (cfg.keep_alive != null) {inherit (cfg) keep_alive;}
    // lib.optionalAttrs (cfg.tunnels != []) {
      tunnels = map mkTunnel cfg.tunnels;
    };
  hasConfig = cfg.tunnels != [];

  # Supervised main process for launchd/systemd: takes over the socket
  # from any stray daemon (spawned by a manual `boring open` or leaked from
  # a previous session), runs the daemon in the background, opens all
  # tunnels once the socket accepts connections, then waits on the daemon
  # so the service manager restarts the whole setup when the daemon dies.
  #
  # `open --all` exits non-zero if any tunnel fails (e.g. network not up
  # yet right after login) and treats already-open tunnels as success, so
  # retrying is idempotent. BORING_NO_SPAWN stops the client from spawning
  # its own unsupervised daemon when the supervised one is still starting.
  daemonSupervised = pkgs.writeShellApplication {
    name = "boring-daemon-supervised";
    runtimeInputs = [pkgs.coreutils] ++ lib.optionals (!isDarwin) [pkgs.procps];
    text = ''
      export BORING_NO_SPAWN=1
      export BORING_CONFIG="${configFile}"

      pkill -f "boring --daemon" 2>/dev/null || true
      for _ in $(seq 1 50); do
        if ! ${boringExe} list >/dev/null 2>&1; then
          break
        fi
        sleep 0.2
      done

      ${boringExe} --daemon &
      daemon_pid=$!
      opened=0
      for _ in $(seq 1 150); do
        if ! kill -0 "$daemon_pid" 2>/dev/null; then
          wait "$daemon_pid"
          exit 1
        fi
        if ${boringExe} open --all; then
          opened=1
          break
        fi
        sleep 2
      done
      if [ "$opened" -ne 1 ]; then
        echo "boring: could not open all tunnels; run 'boring open --all' to retry" >&2
      fi
      wait "$daemon_pid"
    '';
  };
in {
  options.dotnix.apps.boring = {
    enable = lib.mkEnableOption "boring SSH tunnel manager";

    autoStart = lib.mkEnableOption "the boring daemon as a user service, opening all configured tunnels at login";

    package = lib.mkOption {
      type = lib.types.package;
      default = boringPkg;
      description = "boring package to use";
    };

    keep_alive = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Global keep-alive interval in seconds (default: 120)";
    };

    tunnels = lib.mkOption {
      type = lib.types.listOf tunnelType;
      default = [];
      description = "Tunnel definitions";
      example = lib.literalExpression ''
        [
          {
            name = "dev";
            local = "9000";
            remote = "localhost:9000";
            host = "dev-server";
          }
          {
            name = "prod";
            local = "5001";
            remote = "localhost:5001";
            host = "prod.example.com";
            user = "root";
            identity = "~/.ssh/id_prod";
          }
        ]
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      dotnix.hm.packages = [cfg.package];

      home-manager = dotnix-utils.hm.hmConfig (
        lib.optionalAttrs hasConfig {
          xdg.configFile."boring/.boring.toml" = {
            source = (pkgs.formats.toml {}).generate "boring-config" boringConfig;
            force = true;
          };
          home.sessionVariables = lib.optionalAttrs isDarwin {
            BORING_CONFIG = configFile;
          };
        }
      );
    }

    (lib.mkIf (cfg.autoStart && hasConfig) (lib.mkMerge [
      (lib.optionalAttrs (!isDarwin) {
        # Start the user systemd manager at boot so tunnels come up without
        # an active login session.
        users.users.${user.name}.linger = true;
      })

      {
        home-manager = dotnix-utils.hm.hmConfig (lib.mkMerge [
          (lib.optionalAttrs (!isDarwin) {
            systemd.user.services.boring = {
              Unit.Description = "boring SSH tunnel manager daemon";
              Service = {
                ExecStart = lib.getExe daemonSupervised;
                Restart = "on-failure";
                RestartSec = "2s";
              };
              Install.WantedBy = ["default.target"];
            };
          })

          (lib.optionalAttrs isDarwin {
            launchd.agents.boring = {
              enable = true;
              config = {
                Label = "com.dotnix.boring";
                ProgramArguments = [(lib.getExe daemonSupervised)];
                RunAtLoad = true;
                # Restart on crash, but stay down after a clean (deliberate) exit.
                KeepAlive.SuccessfulExit = false;
                StandardOutPath = "${homeDir}/Library/Logs/boring.stdout.log";
                StandardErrorPath = "${homeDir}/Library/Logs/boring.stderr.log";
              };
            };
          })
        ]);
      }
    ]))

    (lib.mkIf (cfg.autoStart && !hasConfig) {
      warnings = [
        "dotnix.apps.boring.autoStart is set but no tunnels are configured; the boring daemon will not be started."
      ];
    })
  ]);
}
