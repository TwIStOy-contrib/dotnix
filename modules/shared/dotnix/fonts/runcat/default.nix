{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dotnix.fonts.runcat;

  runcat = pkgs.stdenv.mkDerivation {
    pname = "runcat";
    version = "1.0.0";
    src = ./assets/runcat.ttf;
    # Don't let stdenv try to unpack a .ttf as an archive.
    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      install -Dm644 ${./assets/runcat.ttf} $out/share/fonts/truetype/runcat.ttf
      runHook postInstall
    '';

    meta = {
      description = "RunCat icon font (icomoon) for pi-runcat loading indicator";
      platforms = lib.platforms.all;
    };
  };
in {
  options.dotnix.fonts.runcat = {
    enable = lib.mkEnableOption ''
      Install the RunCat icon font (family name "icomoon", code points
      U+E900-U+E904) used by the pi-runcat loading indicator.
    '';
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = [runcat];
  };
}
