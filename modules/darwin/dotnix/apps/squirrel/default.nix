{
  config,
  pkgs,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.squirrel;

  oh-my-rime = pkgs.fetchFromGitHub {
    owner = "Mintimate";
    repo = "oh-my-rime";
    rev = "1d93351a15f8b9dd66847ee887374c962bea4764";
    hash = "sha256-hDWJBBZQsROD5qp8XNqChgJhLODLAjg819/Y5q3dlIc=";
  };

  # Wanxiang (万象) language model for Rime. Improves long-sentence accuracy.
  # Ref: https://www.mintimate.cc/zh/guide/languageModel.html
  # Upstream: https://github.com/amzxyz/RIME-LMDG (LTS release)
  # Referenced from double_pinyin_flypy.custom.yaml as `grammar/language`.
  #
  # NOTE: The upstream LTS release is mutable (`isImmutable: false`); its
  # assets get re-uploaded periodically, which changes the content hash and
  # breaks reproducible Nix fetches. We pin to an immutable mirror under
  # TwIStOy-contrib/rime-assets instead. To move to a newer snapshot, create
  # a new immutable release (v2, v3, ...) there and bump both `url` and
  # `hash` — never overwrite an existing versioned release.
  wanxiang-gram = pkgs.fetchurl {
    url = "https://github.com/TwIStOy-contrib/rime-assets/releases/download/v1/wanxiang-lts-zh-hans.gram";
    hash = "sha256-5+DhVkiYe1Bx3AohNc9BeQycvCe7tqYqjeD+Ljqivzo=";
  };
in {
  options.dotnix.apps.squirrel = {
    enable = lib.mkEnableOption "Squirrel - Rime for Mac";
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "Squirrel only works on macOS";
      }
    ];

    homebrew = {
      casks = ["squirrel-app"];
    };

    home-manager = dotnix-utils.hm.hmConfig {
      home.file = {
        # Base oh-my-rime sources, deployed recursively under ~/Library/Rime.
        # Per-file entries below (the *.custom.yaml) are merged on top by
        # home-manager — different `home.file.<key>` keys never collide.
        "Library/Rime" = {
          source = oh-my-rime;
          recursive = true;
        };

        # User overrides. Use the `.custom.yaml` mechanism so the upstream
        # oh-my-rime files stay stock and updates just work.
        # Ref: https://www.mintimate.cc/zh/guide/configurationOverride.html
        "Library/Rime/default.custom.yaml".source = ./custom/default.custom.yaml;
        "Library/Rime/double_pinyin_flypy.custom.yaml".source = ./custom/double_pinyin_flypy.custom.yaml;
        "Library/Rime/squirrel.custom.yaml".source = ./custom/squirrel.custom.yaml;

        # Wanxiang language model. Loaded by double_pinyin_flypy.custom.yaml
        # via `grammar/language: wanxiang-lts-zh-hans`.
        "Library/Rime/wanxiang-lts-zh-hans.gram".source = wanxiang-gram;
      };
    };
  };
}
