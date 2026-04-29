{
  pkgs,
  dotnix-constants,
  ...
}: let
  inherit (dotnix-constants) user;

  caBundle = pkgs.runCommand "ca-bundle-zscaler" {} ''
    cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt ${./zscaler-root-ca.pem} > $out
  '';
in {
  nix = {
    enable = true;

    package = pkgs.nix;

    settings.auto-optimise-store = false;

    gc.automatic = false;

    extraOptions = ''
      ssl-cert-file = ${caBundle}
    '';
  };

  nixpkgs.config.allowUnfree = true;

  # Required for options that previously applied to invoking user (system.defaults.* etc.)
  system.primaryUser = user.name;

  users.users."${user.name}" = {
    home = "/Users/${user.name}";
  };
}
