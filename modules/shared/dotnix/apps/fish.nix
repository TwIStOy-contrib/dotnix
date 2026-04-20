{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.fish;
in {
  options.dotnix.apps.fish = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.fish";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.fish = {
        enable = true;
        package = pkgs-unstable.fish;
        interactiveShellInit = ''
          set fish_greeting

          export GITHUB_TOKEN="$(cat ${config.age.secrets.github-cli-access-token.path})"
        '';
        plugins = [
          {
            name = "foreign-env";
            src = pkgs.fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "plugin-foreign-env";
              rev = "3ee95536106c11073d6ff466c1681cde31001383";
              sha256 = "sha256-vyW/X2lLjsieMpP9Wi2bZPjReaZBkqUbkh15zOi8T4Y=";
            };
          }
        ];
        shellAliases = {
          ll = "eza -l --icons -a --group-directories-first --git";
          glr = "git pull --rebase";
          gco = "git checkout";
          gst = "git status";
          gd = "git diff";
          glg = "git log --graph";
          gaa = "git add --all";
          gcm = "git commit -m";
          gp = "git push";
          nvi = "nvim";
          v = "nvim";
          j = "just";
          lg = "lazygit";
          tdev = "tmux atta -t dev || tmux new -s dev";
          goto = "kitten ssh --kitten forward_remote_control=yes";
          ts = "tailscale";
        };
      };
    };
  };
}
