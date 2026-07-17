{
  config,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.nixos-shared-suit;
  inherit (dotnix-utils) enabled;
in {
  options.dotnix.nixos-shared-suit = {
    enable = lib.mkEnableOption "Enable shared-suit for all nixos hosts.";
  };

  config = lib.mkIf cfg.enable {
    dotnix = {
      shared-suit = enabled;
      system-tools = enabled;
      nixos-shared = enabled;
      services.mihomo = enabled;
    };
  };
}
