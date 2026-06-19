{
  config,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.shared-suit;
  inherit (dotnix-utils) enabled;
in {
  options.dotnix.shared-suit = {
    enable = lib.mkEnableOption "Enable shared-suit for all hosts.";
  };

  config = lib.mkIf cfg.enable {
    dotnix.suits = {
      development = enabled;
      devops = enabled;
      term = enabled;
    };

    # RunCat icon font (icomoon, U+E900-U+E904) for the pi-runcat
    # loading indicator. Installed on every host so the codepoint maps
    # in kitty/ghostty always resolve.
    dotnix.fonts.runcat = enabled;
  };
}
