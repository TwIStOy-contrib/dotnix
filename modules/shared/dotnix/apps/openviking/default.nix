{
  config,
  lib,
  inputs,
  dotnix-utils,
  dotnix-constants,
  dotnix-pkgs,
  ...
}: let
  cfg = config.dotnix.apps.openviking;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;
  hm-dag = inputs.home-manager.lib.hm.dag;
  keyPath = config.age.secrets."${cfg.apiKeySecret}".path;
  connectionFile = "${homeDir}/.openviking/ovcli.conf";
in {
  options.dotnix.apps.openviking = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.openviking";

    url = lib.mkOption {
      type = lib.types.str;
      default = "https://api.vikingdb.cn-beijing.volces.com/openviking";
      description = "OpenViking server the CLI and agent plugins connect to.";
    };

    apiKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "openviking-cloud-user-key";
      description = "Name of the agenix secret holding the OpenViking API key.";
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      dotnix-pkgs.openviking-cli
    ];

    home-manager = dotnix-utils.hm.hmConfig {
      # agenix owns the credential; derive the connection file the OpenViking
      # CLI and plugins read from it rather than keeping a second copy.
      home.activation.openviking-client-config = hm-dag.entryAfter ["linkGeneration"] ''
        if [ -r ${lib.escapeShellArg keyPath} ]; then
          $DRY_RUN_CMD install -d -m 700 ${lib.escapeShellArg "${homeDir}/.openviking"}
          (umask 077; printf '{\n  "url": "%s",\n  "api_key": "%s"\n}\n' \
            ${lib.escapeShellArg cfg.url} "$(cat ${lib.escapeShellArg keyPath})" \
            | $DRY_RUN_CMD tee ${lib.escapeShellArg connectionFile} >/dev/null)
        fi
      '';
    };
  };
}
