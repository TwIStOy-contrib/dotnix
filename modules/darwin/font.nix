{
  pkgs,
  pkgs-unstable,
  secrets-hawtian,
  lib,
  ...
}: let
  mapleMono = pkgs-unstable.maple-mono.NF-CN-unhinted.overrideAttrs (finalAttrs: _: {
    version = "8.0-beta.3";
    src = pkgs-unstable.fetchurl {
      url = "https://github.com/subframe7536/maple-font/releases/download/v${finalAttrs.version}/${finalAttrs.pname}.zip";
      hash = "sha256-ZvaxraUJE+ipzoE06RqwvNPYTgd+MCF0c1hFKvhDpBc=";
    };
  });

  monolisa = pkgs.stdenv.mkDerivation {
    pname = "monolisa";
    version = "2.015";
    src = "${secrets-hawtian}/fonts/MonoLisa";

    installPhase = ''
      runHook preInstall
      install -Dm644 *.ttf -t $out/share/fonts/truetype
      runHook postInstall
    '';

    meta = {
      description = "Monolisa font";
      platforms = lib.platforms.all;
    };
  };

  akzidenz-grotesk = pkgs.stdenv.mkDerivation {
    pname = "akzidenz-grotesk";
    version = "1.0";
    src = "${secrets-hawtian}/fonts/Akzidenz-Grotesk";

    installPhase = ''
      runHook preInstall
      install -Dm644 *.otf -t $out/share/fonts/truetype
      runHook postInstall
    '';

    meta = {
      description = "Akzidenz Grotesk font";
      platforms = lib.platforms.all;
    };
  };

  readex-pro = pkgs.stdenv.mkDerivation {
    pname = "readex-pro";
    version = "1.0";
    src = "${secrets-hawtian}/fonts/ReadexPro";

    installPhase = ''
      runHook preInstall
      install -Dm644 *.ttf -t $out/share/fonts/truetype
      runHook postInstall
    '';

    meta = {
      description = "Readex font";
      platforms = lib.platforms.all;
    };
  };
in {
  fonts.packages =
    [
      monolisa
      akzidenz-grotesk
      readex-pro

      mapleMono
      pkgs-unstable.monaspace
      pkgs-unstable.lxgw-wenkai-screen
    ]
    ++ (with pkgs-unstable.nerd-fonts; [
      symbols-only
      fira-code
      jetbrains-mono
      iosevka
      monaspace
    ]);
}
