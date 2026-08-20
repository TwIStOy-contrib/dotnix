{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.dotnix.development.languages.dart;
in {
  options.dotnix.development.languages.dart = {
    enable = lib.mkEnableOption "Enable Dart";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages =
      if pkgs.stdenv.hostPlatform.isDarwin
      then
        with pkgs; [
          dart
          cocoapods
        ]
      else
        with pkgs; [
          flutter
        ];
  };
}
