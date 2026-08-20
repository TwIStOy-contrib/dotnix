{
  config,
  pkgs,
  lib,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.git;
in {
  options.dotnix.apps.git = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.git";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.git = {
        enable = true;
        lfs.enable = true;

        settings =
          {
            user.name = dotnix-constants.user.fullName;
            user.email = dotnix-constants.user.email;
            init.defaultBranch = "master";
            push.autoSetupRemote = true;
            pull.rebase = false;
            gpg.format = "ssh";
            core.excludesfile = "~/.config/git/ignore";
          }
          // (lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
            "gpg \"ssh\"".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          });

        signing = {
          # darwin: sign with the main key held by 1Password;
          # elsewhere: sign with the dedicated key decrypted by agenix
          key =
            if pkgs.stdenv.hostPlatform.isDarwin
            then "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG92SyvgOOe9pGPGHEY9VbDBWwqaRgm9tg1RJUxlfdCN"
            else config.age.secrets.remote-sign-key.path;
          signByDefault = true;
        };
      };

      xdg.configFile."git/ignore" = {
        source = ./gitignore;
        force = true;
      };
    };
  };
}
