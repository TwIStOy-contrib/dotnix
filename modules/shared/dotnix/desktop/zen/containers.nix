{
  config,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.desktop.zen;
in {
  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.zen-browser.profiles.default = {
        containersForce = true;
        containers = {
          personal = {
            id = 1;
            name = "Personal";
            icon = "fingerprint";
            color = "blue";
          };
          work = {
            id = 2;
            name = "Work";
            icon = "briefcase";
            color = "orange";
          };
          banking = {
            id = 3;
            name = "Banking";
            icon = "dollar";
            color = "green";
          };
          shopping = {
            id = 4;
            name = "Shopping";
            icon = "cart";
            color = "pink";
          };
        };
      };
    };
  };
}
