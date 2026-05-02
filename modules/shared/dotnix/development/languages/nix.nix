{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.dotnix.development.languages.nix;
in {
  options.dotnix.development.languages.nix = {
    enable = lib.mkEnableOption "Enable nix";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = with pkgs; [
      nil
      statix
      deadnix
      alejandra
      nix-output-monitor
      cachix

      nixpkgs-fmt
      nixpkgs-lint
      nixpkgs-review
    ];
  };
}
