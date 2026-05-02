{
  pkgs,
  config,
  lib,
  dotnix-constants,
  ...
}: let
  inherit (dotnix-constants) user;

  cfg = config.dotnix.darwin.zscaler-ca;

  caBundle = pkgs.runCommand "ca-bundle-zscaler" {} ''
    cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt ${./zscaler-root-ca.pem} > $out
  '';
in {
  options.dotnix.darwin.zscaler-ca = {
    enable = lib.mkEnableOption "Zscaler CA bundle for nix";
  };

  config = {
    nix = {
      enable = true;

      package = pkgs.nix;

      settings.auto-optimise-store = false;

      gc.automatic = false;

      extraOptions = lib.optionalString cfg.enable ''
        ssl-cert-file = ${caBundle}
      '';
    };

    nixpkgs.config.allowUnfree = true;

    system.primaryUser = user.name;

    users.users."${user.name}" = {
      home = "/Users/${user.name}";
    };
  };
}
