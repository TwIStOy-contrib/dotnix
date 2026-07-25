#!/usr/bin/env python3
# Preview every sketchybar-app-font PUA glyph in your terminal.
#
# Prints each Private Use Area codepoint assigned by the remapper, so you can
# eyeball whether the glyphs render correctly in kitty/ghostty after the
# symbol_map / font-codepoint-map routing is in place. Dev/inspection tool,
# NOT part of the installed package.
#
# The codepoints are contiguous and known (see default.nix), so this just
# walks U+100000..U+10026F and prints each char — no font introspection.
# Uses only the stdlib (chr()), so no nix-shell or fonttools needed.
#
# Usage:
#   ./preview-icons.sh                   # default range
#   START=100000 END=10026F ./preview-icons.sh
import os
import sys

start = int(os.environ.get("START", "100000"), 16)
end = int(os.environ.get("END", "10026F"), 16)
if end < start:
    sys.exit("START must be <= END")

count = end - start + 1
print(f"PUA range: U+{start:05X} .. U+{end:05X}")
print(f"codepoints: {count}")
print()
print(f"{'codepoint':<12} glyph")
print("-" * 30)
out = sys.stdout
for cp in range(start, end + 1):
    out.write(f"U+{cp:05X}      {chr(cp)} \n")
