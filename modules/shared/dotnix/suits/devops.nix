{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.suits.devops;
in {
  options.dotnix.suits.devops = {
    enable = lib.mkEnableOption "Enable module dotnix.suits.devops";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      home.packages =
        (with pkgs; [
          lazydocker # docker TUI
          dive # explore layers in docker images
          kubernetes-helm
          fluxcd
          # ansible
          fluxcd
        ])
        ++ (
          with pkgs-unstable; [
            minikube # k8s
            kubectx
            kubelogin-oidc
            squashfsTools
            flyctl
          ]
        );
    };
  };
}
