{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.dotnix.apps.htw;
  htw = inputs.htw.packages.${pkgs.system}.default;
in {
  options.dotnix.apps.htw = {
    enable = lib.mkEnableOption "htw, the developer environment manager CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = htw;
      defaultText = lib.literalExpression "inputs.htw.packages.\${pkgs.system}.default";
      description = "Package providing the htw binary.";
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      cfg.package
    ];
  };
}
