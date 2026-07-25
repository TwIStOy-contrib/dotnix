#!/usr/bin/env python3
"""Remap a ligature-based icon font to also expose Private Use Area codepoints.

sketchybar-app-font works by OpenType ligature substitution: the literal text
":pi:" (5 ASCII codepoints) is replaced by a single icon glyph via the font's
GSUB table. Terminals such as kitty/ghostty cannot render these icons because
their font fallback only triggers on missing *codepoints*, and the ASCII
characters (`:`, `p`, `i`) all exist in the primary text font — so the ligature
GSUB of sketchybar-app-font is never consulted.

This script rewrites the font so each ligature target glyph is *also* assigned
a PUA codepoint (default U+F534..U+F8FF, a region free in Maple Mono NF CN).
Terminals can then route that PUA range to this font via `symbol_map` (kitty) /
`font-codepoint-map` (ghostty), and the generated icon_map.sh/lua emit the PUA
character directly instead of the `:iconname:` token.

The original GSUB ligature table is preserved, so the font stays usable by
sketchybar itself (which renders via Cocoa/NSFont and handles ligatures
natively). The font is therefore "dual mode".

Inputs:
  --in-font PATH        ligature TTF to read (and augment with PUA cmap)
  --mappings-dir PATH   upstream mappings/ dir: file ":pi:" -> app names
  --out-font PATH       PUA-augmented TTF to write
  --pua-start HEX       first PUA codepoint (default F534)
  --pua-end HEX         last PUA codepoint (default F8FF); aborts if too small
  --out-icon-map-sh     write PUA bash icon_map (app name -> PUA char)
  --out-icon-map-lua    write PUA lua icon_map

App-name -> icon mapping comes from mappings/ (same source upstream's own
icon_map.sh uses); icon -> PUA codepoint comes from the font's GSUB + the
sequential PUA assignment. The merged output is a drop-in replacement for
upstream icon_map.sh, only the values change from ":pi:" to the PUA char.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from fontTools.ttLib import TTFont


def read_ligatures(font: TTFont) -> list[tuple[str, str]]:
    """Return [(icon_name, ligature_glyph_name)] for every GSUB type-4 lookup.

    icon_name is the bare token (e.g. "pi"), derived from the ligature's output
    glyph name by stripping the surrounding colons the font uses internally.
    """
    if "GSUB" not in font:
        raise SystemExit("font has no GSUB table; cannot read ligatures")
    gsub = font["GSUB"].table
    out: list[tuple[str, str]] = []
    seen: set[str] = set()
    for lookup in gsub.LookupList.Lookup:
        if lookup.LookupType != 4:  # 4 == LigatureSubst
            continue
        for subtable in lookup.SubTable:
            for first_glyph, ligatures in subtable.ligatures.items():
                for lig in ligatures:
                    name = lig.LigGlyph
                    # Upstream glyph names look like ":pi:", ":safari:", etc.
                    icon = name.strip(":")
                    if icon and icon not in seen:
                        seen.add(icon)
                        out.append((icon, name))
    out.sort(key=lambda x: x[0])
    return out


def read_mappings(mappings_dir: Path) -> list[tuple[str, str]]:
    """Return [(app_pattern, icon_name)] parsed from upstream mappings/ files.

    Each file in mappings/ is named like ":pi:" and its body is a
    pipe-separated list of app-name patterns. The patterns are written
    verbatim (they already carry their own double quotes in the source, e.g.
    '"Activity Monitor"'), so a multi-word or non-ASCII name becomes a legal
    bash case alternative and a lua key unchanged.
    """
    out: list[tuple[str, str]] = []
    if not mappings_dir.is_dir():
        raise SystemExit(f"mappings dir not found: {mappings_dir}")
    for f in sorted(mappings_dir.iterdir()):
        icon = f.name.removeprefix(":").removesuffix(":")
        if not icon:
            continue
        body = f.read_text(encoding="utf-8").strip()
        for app in body.split("|"):
            app = app.strip()
            if app:
                out.append((app, icon))
    return out


def assign_pua(
    ligatures: list[tuple[str, str]],
    start: int,
    end: int,
) -> dict[str, int]:
    """Return {icon_name: pua_codepoint}."""
    capacity = end - start + 1
    if len(ligatures) > capacity:
        raise SystemExit(
            f"PUA range U+{start:04X}-U+{end:04X} holds {capacity} codepoints, "
            f"but {len(ligatures)} icons are needed"
        )
    return {icon: start + i for i, (icon, _glyph) in enumerate(ligatures)}


def write_font(
    font: TTFont,
    icon_to_cp: dict[str, int],
    out: Path,
    glyph_width: int,
) -> None:
    # Update EVERY cmap subtable that covers Unicode (the BMP-only format 4
    # ones AND the full-Unicode format 12 ones). If we only patch one, the
    # others shadow it: fontTools getBestCmap() and real text stacks prefer
    # format 12, which would mask PUA codepoints added only to format 4.
    cmap_table = font["cmap"]
    # Map icon -> glyph name via GSUB (re-read to preserve order independence).
    gsub = font["GSUB"].table
    icon_to_glyph: dict[str, str] = {}
    for lookup in gsub.LookupList.Lookup:
        if lookup.LookupType != 4:
            continue
        for sub in lookup.SubTable:
            for _first, ligatures in sub.ligatures.items():
                for lig in ligatures:
                    icon = lig.LigGlyph.strip(":")
                    if icon:
                        icon_to_glyph.setdefault(icon, lig.LigGlyph)

    patched_subtables = 0
    for st in cmap_table.tables:
        # Only patch Unicode subtables (platform 0 or 3). Skip the legacy
        # Macintosh (platform 1) subtable; it has no PUA glyphs anyway.
        if st.platformID not in (0, 3):
            continue
        # format 4 / format 0 are 16-bit only and OverflowError on anything
        # above U+FFFF. Only format 12 (segmented coverage) holds full-Unicode
        # codepoints, so restrict PUA writes to format-12 subtables. If the
        # target range is entirely within the BMP this also works because
        # format-12 happily stores BMP codepoints too.
        if getattr(st, "format", None) != 12:
            continue
        for icon, cp in icon_to_cp.items():
            glyph = icon_to_glyph[icon]
            if cp in st.cmap and st.cmap[cp] != glyph:
                raise SystemExit(
                    f"codepoint U+{cp:04X} already mapped in cmap subtable "
                    f"(platform={st.platformID} platEncID={st.platEncID}) "
                    f"to '{st.cmap[cp]}'; refusing to overwrite"
                )
            st.cmap[cp] = glyph
        patched_subtables += 1
    if patched_subtables == 0:
        raise SystemExit(
            "no format-12 Unicode cmap subtable found; the source font needs "
            "one to store supplementary-plane codepoints"
        )

    # Fix advance widths for the PUA glyphs. The source font comes from
    # svgtofont configured for sketchybar (Cocoa text renderer): every icon
    # glyph has advance ~1411 units, which is ~2.35x a normal monospace cell.
    # Terminals size cells from the primary font's advance (e.g. Maple Mono NF
    # CN uses 600 out of unitsPerEm=1000), so an icon at advance 1411 spills
    # across cells and either renders off-center, clipped, or invisible.
    # Rewriting each PUA glyph's advance to `glyph_width` (default 600, one
    # cell) makes the icon fit. We keep the original LSB so the glyph stays
    # at its drawn x offset within that cell.
    hmtx = font["hmtx"]
    for icon, cp in icon_to_cp.items():
        glyph = icon_to_glyph[icon]
        _w, lsb = hmtx[glyph]
        hmtx[glyph] = (glyph_width, lsb)

    font.save(str(out))


def _cp_literal(cp: int) -> str:
    """Return the literal Unicode character for a codepoint.

    We write the raw UTF-8 character into the generated map files rather than
    a backslash-u hex escape. Escape support is inconsistent across shells:
    stock bash 5.3 (as shipped on macOS via nix) does not decode the short or
    long unicode escapes in dollar-single-quote ANSI-C quoting, and older
    bashes vary too. A literal character is read correctly by every shell and
    every Lua version. For supplementary-plane codepoints this embeds a 4-byte
    UTF-8 sequence.
    """
    return chr(cp)


def write_icon_map_sh(
    mappings: list[tuple[str, str]],
    icon_to_cp: dict[str, int],
    out: Path,
) -> None:
    """Emit upstream-shaped icon_map.sh with literal PUA chars as values.

    Mirrors upstream build.js: each mapping file's app list becomes a case
    branch, multiple apps sharing an icon share a branch. The only change is
    the icon_result value: instead of ":pi:" we write the literal PUA char.
    """
    # Group by icon to preserve upstream's combined-case-branch shape.
    by_icon: dict[str, list[str]] = {}
    for app, icon in mappings:
        by_icon.setdefault(icon, []).append(app)
    lines = [
        "#!/usr/bin/env bash",
        "# Auto-generated by remap_to_pua.py: app name -> PUA character.",
        "# The PUA codepoints are routed to sketchybar-app-font by kitty/ghostty",
        "# config (see modules/shared/dotnix/fonts/sketchybar-app-font). Values",
        "# are raw UTF-8 chars (not \\u escapes) for shell portability.",
        "### START-OF-ICON-MAP",
        'function __icon_map() {',
        '    case "$1" in',
    ]
    for icon in sorted(by_icon):
        if icon not in icon_to_cp:
            continue
        apps = " | ".join(by_icon[icon])
        cp = icon_to_cp[icon]
        lit = _cp_literal(cp)
        # Double-quote the value: supplementary-plane chars are wide and the
        # literal bytes must be a single shell token.
        lines.append(f"        {apps})")
        lines.append(f'            icon_result="{lit}"')
        lines.append("            ;;")
    lines.append("        *)")
    lines.append('            icon_result=":default:"')
    lines.append("            ;;")
    lines.append("    esac")
    lines.append("}")
    lines.append("### END-OF-ICON-MAP")
    lines.append("")
    lines.append('# When executed directly, map all arguments and print space-separated results.')
    lines.append('if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then')
    lines.append('    for app_name in "$@"; do')
    lines.append('        __icon_map "$app_name"')
    lines.append('        printf "%s " "$icon_result"')
    lines.append('    done')
    lines.append('    [[ $# -gt 0 ]] && printf "\\n"')
    lines.append("fi")
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_icon_map_lua(
    mappings: list[tuple[str, str]],
    icon_to_cp: dict[str, int],
    out: Path,
) -> None:
    lines = [
        "-- Auto-generated by remap_to_pua.py: app name -> PUA character.",
        "-- Values are raw UTF-8 chars (not backslash-u escapes) for Lua portability.",
        "return {",
    ]
    for app, icon in mappings:
        if icon not in icon_to_cp:
            continue
        cp = icon_to_cp[icon]
        lit = _cp_literal(cp)
        # Lua keys are stripped of the surrounding double quotes the upstream
        # mappings carry (those quotes exist for bash case-pattern syntax).
        # [[...]] long-bracket key syntax keeps multi-word / non-ASCII names
        # literal without extra escaping.
        key = app.strip().strip('"')
        lines.append(f'\t[ [[{key}]] ] = "{lit}",')
    lines.append("}")
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--in-font", required=True, type=Path)
    ap.add_argument("--mappings-dir", required=True, type=Path)
    ap.add_argument("--out-font", required=True, type=Path)
    ap.add_argument("--pua-start", default="F534")
    ap.add_argument("--pua-end", default="F8FF")
    ap.add_argument("--out-icon-map-sh", type=Path)
    ap.add_argument("--out-icon-map-lua", type=Path)
    ap.add_argument(
        "--glyph-width",
        type=int,
        default=600,
        help=(
            "Advance width (in font units) to assign every PUA icon glyph. "
            "The source font sets ~1411, which spills across terminal cells "
            "and renders off-center or invisible. Default 600 matches a "
            "monospace cell at unitsPerEm=1000 (e.g. Maple Mono NF CN)."
        ),
    )
    args = ap.parse_args()

    start = int(args.pua_start, 16)
    end = int(args.pua_end, 16)

    font = TTFont(str(args.in_font))
    ligatures = read_ligatures(font)
    print(f"found {len(ligatures)} ligatures in {args.in_font}", file=sys.stderr)

    icon_to_cp = assign_pua(ligatures, start, end)
    last_cp = start + len(icon_to_cp) - 1
    print(
        f"assigned PUA U+{start:04X}-U+{last_cp:04X} "
        f"({len(icon_to_cp)} of {end - start + 1} available)",
        file=sys.stderr,
    )

    args.out_font.parent.mkdir(parents=True, exist_ok=True)
    write_font(font, icon_to_cp, args.out_font, args.glyph_width)
    print(f"wrote font: {args.out_font}", file=sys.stderr)
    print(f"PUA glyph advance width set to {args.glyph_width}", file=sys.stderr)

    mappings = read_mappings(args.mappings_dir)
    print(f"read {len(mappings)} app->icon mappings from {args.mappings_dir}", file=sys.stderr)

    if args.out_icon_map_sh:
        write_icon_map_sh(mappings, icon_to_cp, args.out_icon_map_sh)
        print(f"wrote bash map: {args.out_icon_map_sh}", file=sys.stderr)
    if args.out_icon_map_lua:
        write_icon_map_lua(mappings, icon_to_cp, args.out_icon_map_lua)
        print(f"wrote lua map: {args.out_icon_map_lua}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
