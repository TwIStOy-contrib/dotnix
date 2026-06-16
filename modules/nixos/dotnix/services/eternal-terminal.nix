{
  config,
  lib,
  ...
}: let
  cfg = config.dotnix.services.eternal-terminal;
in {
  options.dotnix.services.eternal-terminal = {
    enable = lib.mkEnableOption "Enable module dotnix.services.eternal-terminal";

    port = lib.mkOption {
      type = lib.types.port;
      default = 2022;
      description = "Port for etserver to listen on.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.eternal-terminal = {
      enable = true;
      port = cfg.port;
    };

    # Open the firewall for inbound et connections.
    networking.firewall.allowedTCPPorts = [cfg.port];
  };
}
