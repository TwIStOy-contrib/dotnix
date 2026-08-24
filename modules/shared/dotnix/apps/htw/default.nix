{
  config,
  lib,
  pkgs,
  inputs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.htw;
  htw = inputs.htw.packages.${pkgs.stdenv.hostPlatform.system}.default;
  htwBin = lib.getExe cfg.package;
  fishCompletion = pkgs.runCommandLocal "htw-fish-completion" {} ''
    ${htwBin} completion fish >"$out"
  '';
  fishIntegration = pkgs.runCommandLocal "htw-fish-integration" {} ''
    export XDG_CONFIG_HOME="$TMPDIR/xdg"
    ${htwBin} shell install >/dev/null
    cp "$XDG_CONFIG_HOME/fish/functions/htw.fish" "$out"
  '';
in {
  options.dotnix.apps.htw = {
    enable = lib.mkEnableOption "htw, the developer environment manager CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = htw;
      defaultText = lib.literalExpression "inputs.htw.packages.\${pkgs.stdenv.hostPlatform.system}.default";
      description = "Package providing the htw binary.";
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      cfg.package
    ];

    home-manager = lib.mkIf config.dotnix.apps.fish.enable (dotnix-utils.hm.hmConfig {
      xdg.configFile = {
        "fish/completions/htw.fish".source = fishCompletion;
        "fish/functions/htw.fish".source = fishIntegration;
      };
    });
  };
}
