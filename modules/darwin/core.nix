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
    enable = lib.mkEnableOption "Zscaler CA for Nix ssl-cert-file and user TLS (curl/OpenSSL, Node via home.sessionVariables)";
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

    # Same PEM as nix.settings.ssl-cert-file: Mozilla CA + Zscaler root (modules/darwin/zscaler-root-ca.pem).
    home-manager.users.${user.name}.home.sessionVariables = lib.mkIf cfg.enable {
      NIX_SSL_CERT_FILE = "${caBundle}";
      SSL_CERT_FILE = "${caBundle}";
      NODE_EXTRA_CA_CERTS = "${caBundle}";
    };
  };
}
