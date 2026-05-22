#!/bin/sh
# 05 — Explicit color-mode override.
#
# Surface: --color <mode> overrides the auto-detection chain. M6
# (v0.7.0) shipped four modes: 24bit (truecolor), 256, 16, none.
#
# Expected: same input, four different palette renderings. On a
# 24-bit-capable terminal the first looks smoothest; 256 is
# noticeably banded; 16 collapses to the ANSI bright palette; none
# is plain text.
#
# Cite: src/color.cyr (_color_override_from_str /
# anuenue_detect_color_mode / _rgb_to_256 / _rgb_to_16).
# Golden: tests/golden/agnos-rainbow-256-s100.out,
# tests/golden/agnos-rainbow-16-s100.out.

set -eu
ANUENUE=${ANUENUE:-anuenue}

INPUT="AGNOS — ānuenue rainbow"

printf '24bit:  '; echo "$INPUT" | "$ANUENUE" --color=24bit -s 100
printf '256:    '; echo "$INPUT" | "$ANUENUE" --color=256   -s 100
printf '16:     '; echo "$INPUT" | "$ANUENUE" --color=16    -s 100
printf 'none:   '; echo "$INPUT" | "$ANUENUE" --color=none  -s 100

# truecolor is an alias for 24bit; both resolve to the same mode.
echo "$INPUT" | "$ANUENUE" --color=truecolor -s 100
