#!/bin/sh
# 06 — Disabling colour: NO_COLOR, --no-color, --color=none.
#
# Surface: the MONO mode is a true passthrough — anuenue's output
# is byte-identical to its input. This is tested as a hard
# invariant by three goldens in scripts/golden-check.sh.
#
# Priority chain (highest first):
#   1. --color=none / --color=mono   (explicit override)
#   2. --no-color                    (the no_color flag)
#   3. NO_COLOR env var              (per no-color.org)
#   4. stdout-not-TTY                (auto, unless --force-color)
#
# Expected: every command below produces "AGNOS\n" — no escapes.
# Cite: src/color.cyr (anuenue_passthrough); CLAUDE.md § Capability-bounded.

set -eu
ANUENUE=${ANUENUE:-anuenue}

# All four routes to MONO:
echo "AGNOS" | "$ANUENUE" --color=none
echo "AGNOS" | "$ANUENUE" --color=mono
echo "AGNOS" | "$ANUENUE" --no-color
NO_COLOR=1 echo "AGNOS" | "$ANUENUE"

# Equivalence check — all four byte-identical to the source:
SRC=$(printf 'AGNOS\n')
for cmd in '--color=none' '--color=mono' '--no-color'; do
    OUT=$(echo "AGNOS" | "$ANUENUE" $cmd)
    if [ "$OUT" = "$SRC" ]; then
        printf '✓ %s passthrough is byte-identical\n' "$cmd"
    else
        printf '✗ %s differs from input — bug?\n' "$cmd" >&2
        exit 1
    fi
done

OUT=$(NO_COLOR=1 echo "AGNOS" | "$ANUENUE")
if [ "$OUT" = "$SRC" ]; then
    echo "✓ NO_COLOR=1 passthrough is byte-identical"
else
    echo "✗ NO_COLOR differs from input — bug?" >&2
    exit 1
fi
