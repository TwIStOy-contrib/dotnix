{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dotnix.fonts.sketchybar-app-font;

  # PUA range allocated for sketchybar-app-font icons. Must avoid any
  # codepoint used by the primary terminal font (Maple Mono NF CN) so a
  # `symbol_map` / `font-codepoint-map` routing this range here is never
  # shadowed. We use Supplementary PUA-B (U+100000-U+10FFFD), which is
  # completely unused by Maple Mono NF CN across all 16 style variants and
  # can never collide with BMP nerd-font icons (U+E000-U+F8FF). kitty and
  # ghostty both handle supplementary-plane PUA codepoints correctly.
  pua-start = 1048576; # 0x100000
  pua-end = 1114109; # 0x10FFFD
  pua-range-str = "U+${lib.toHexString pua-start}-U+${lib.toHexString pua-end}";

  # Built from the TwIStOy fork of kvndrsslr/sketchybar-app-font, which adds
  # custom icon ligatures (e.g. ":pi:") on top of upstream v2.0.62. The fork
  # carries no release tags, so we pin to a commit.
  #
  # The fork's pnpm-workspace.yaml only declares lifecycle-script approvals.
  # Strip it from this single-package build; fetchPnpmDeps disables scripts.
  rawSrc = pkgs.fetchFromGitHub {
    owner = "TwIStOy";
    repo = "sketchybar-app-font";
    rev = "e64d04646596b60828e30db9705f9fe9696717bb";
    hash = "sha256-bjb3POT7iUsHcR71W2XxUtm3xbcefLF/3WuY8LT6Lxc=";
  };
  src = pkgs.runCommand "sketchybar-app-font-src" {} ''
    cp -r ${rawSrc} $out
    chmod -R u+w $out
    rm -f $out/pnpm-workspace.yaml
  '';

  remapToPua = ./remap_to_pua.py;
  pnpm = pkgs.pnpm_11;

  sketchybar-app-font = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "sketchybar-app-font";
    version = "2.0.62-fork-unstable-2026-07-24";
    inherit src;

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      inherit pnpm;
      fetcherVersion = 4;
      hash = "sha256-zFheFcVSCZWDrThn5PnxhJscRhLG/psSI8Q8g48nXNU=";
    };

    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.pnpmConfigHook
      pnpm
      (pkgs.python3.withPackages (ps: [ps.fonttools]))
    ];

    buildPhase = ''
      runHook preBuild

      pnpm i
      pnpm run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      # Original ligature font (for sketchybar itself, which renders via
      # Cocoa/NSFont and handles OpenType ligatures natively).
      install -Dm644 dist/sketchybar-app-font.ttf "$out/share/fonts/truetype/sketchybar-app-font-ligature.ttf"
      # Original ligature icon_map (":pi:" token form) for sketchybar configs.
      install -Dm755 dist/icon_map.sh "$out/lib/sketchybar-app-font/icon_map.ligature.sh"
      install -Dm644 dist/icon_map.lua "$out/lib/sketchybar-app-font/icon_map.ligature.lua"

      # PUA-augmented font for terminals (kitty/ghostty). Each ligature glyph
      # also gets a PUA codepoint so symbol_map/font-codepoint-map can route it.
      python ${remapToPua} \
        --in-font dist/sketchybar-app-font.ttf \
        --mappings-dir mappings \
        --out-font $out/share/fonts/truetype/sketchybar-app-font.ttf \
        --pua-start ${lib.toHexString pua-start} \
        --pua-end ${lib.toHexString pua-end} \
        --out-icon-map-sh $out/lib/sketchybar-app-font/icon_map.sh \
        --out-icon-map-lua $out/lib/sketchybar-app-font/icon_map.lua
      install -Dm755 $out/lib/sketchybar-app-font/icon_map.sh "$out/bin/icon_map.sh"

      runHook postInstall
    '';

    meta = {
      description = "Ligature-based symbol font and icon map for sketchybar (TwIStOy fork, PUA-mapped for terminals)";
      longDescription = ''
        Built from the TwIStOy fork of kvndrsslr/sketchybar-app-font. The
        install ships two forms of every artefact:

        - Ligature form (sketchybar-app-font-ligature.ttf, icon_map.ligature.*):
          original font, icons rendered via OpenType ligature substitution of
          ":iconname:" text. Used by sketchybar (Cocoa/NSFont renderer).
        - PUA form (sketchybar-app-font.ttf, icon_map.*): the same glyphs also
          exposed at Private Use Area codepoints U+F534-U+F8FF, so terminals
          (kitty/ghostty) can route them via symbol_map/font-codepoint-map.
          Terminals cannot use the ligature form because their font fallback
          only fires on missing codepoints, and ":iconname:" is plain ASCII.
      '';
      homepage = "https://github.com/TwIStOy/sketchybar-app-font";
      license = lib.licenses.cc0;
      platforms = lib.platforms.all;
    };
  });
in {
  options.dotnix.fonts.sketchybar-app-font = {
    enable = lib.mkEnableOption ''
      Install the sketchybar-app-font symbol font (TwIStOy fork) with both
      ligature and PUA codepoint mappings. The derivation also ships
      icon_map.sh / icon_map.lua under bin/ and lib/ (PUA form, for terminals)
      and icon_map.ligature.* (token form, for sketchybar itself).
    '';

    puaRange = lib.mkOption {
      type = lib.types.str;
      default = pua-range-str;
      readOnly = true;
      description = ''
        The PUA codepoint range (kitty/ghostty syntax) assigned to this font's
        icons, for use in symbol_map / font-codepoint-map. Read-only because it
        must stay in sync with the values baked into the font file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = [sketchybar-app-font];
  };
}
