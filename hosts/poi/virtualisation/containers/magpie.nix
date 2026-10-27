{config, ...}: let
  # poi's tailscale address; binding to it restricts both ports to the tailnet
  tailscaleIp = "100.65.0.3";
in {
  virtualisation.docker.enable = true;

  virtualisation.oci-containers = {
    backend = "docker";
    containers.magpie = {
      image = "ghcr.io/yetone/magpie:latest";
      ports = [
        "${tailscaleIp}:3425:3425"
        "${tailscaleIp}:3430:3430"
      ];
      environment = {
        MAGPIE_PUBLIC_URL = "http://${tailscaleIp}:3425";
      };
      # supplies MAGPIE_WEB_KEY (agenix secret, env-file format)
      environmentFiles = [
        config.age.secrets.magpie-web-key.path
      ];
      volumes = [
        "magpie-config:/config"
      ];
      cmd = [
        "web"
        "--addr"
        "0.0.0.0:3430"
        "--no-open"
      ];
    };
  };

  # docker can only publish on the tailscale address once tailscaled has
  # brought up tailscale0
  systemd.services.docker-magpie = {
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
  };
}
