_: let
  hostname = "poi";
in {
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    proxy.default = "http://192.168.50.217:6152";
  };

  systemd.network.wait-online.enable = false;
  systemd.services.NetworkManager-wait-online.enable = false;

  boot = {
    # Bootloader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.systemd.network.wait-online.enable = false;
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  system.stateVersion = "25.05";
}
