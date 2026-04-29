# Common configuration for both darwin and nixos
{
  config,
  dotnix-constants,
  ...
}: let
  inherit (dotnix-constants) user;
in {
  users.users.${user.name} = {
    description = user.fullName;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG92SyvgOOe9pGPGHEY9VbDBWwqaRgm9tg1RJUxlfdCN MainSSH"
    ];
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = [user.name];

    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://twistoy.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "twistoy.cachix.org-1:74RMpK2e+jG514O3MC6KiTb9eJi4pddEnN5h6PBP0aY="
    ];
    builders-use-substitutes = true;
  };

  nix.extraOptions = ''
    !include ${config.age.secrets.nix-secret-conf.path}
  '';

  environment.variables = {
    EDITOR = "nvim";
  };
}
