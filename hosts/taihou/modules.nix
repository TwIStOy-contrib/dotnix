_: {
  dotnix = {
    nixos-shared-suit = {
      enable = true;
    };
    desktop.neovide.extraSettings.font.size = 22;
    apps.ollama = {
      enable = false;
    };
    services.github-runner = {
      enable = false;
    };

    services.tailscale = {
      enable = true;
      extraUpFlags = [
        "--advertise-tags=tag:homeserver"
        "--ssh"
      ];
    };
    services.eternal-terminal = {
      enable = true;
    };
  };
}
