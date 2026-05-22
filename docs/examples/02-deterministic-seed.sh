#!/bin/sh
# 02 — Deterministic seed for byte-identical output.
#
# Surface: -s <int> (alias --seed <int>) sets the starting hue
# phase. With the same seed + same input, anuenue produces the
# exact same byte stream every time. This is the pattern used by
# tests/golden/agnos-rainbow-s100.out (committed fixture).
#
# Expected: both runs produce identical output. `diff` is silent.
#
# Cite: src/main.cyr (ANUENUE_PHASE_START = seed + offset);
# tests/golden/agnos-rainbow-s100.out (golden fixture).
# ADR: docs/adr/0001-pipe-purity.md (no time(2) seed — reproducible
# by design).

set -eu
ANUENUE=${ANUENUE:-anuenue}

# Two runs with the same seed:
echo "AGNOS" | "$ANUENUE" -s 100 > /tmp/anuenue-seed-A.out
echo "AGNOS" | "$ANUENUE" -s 100 > /tmp/anuenue-seed-B.out

if cmp -s /tmp/anuenue-seed-A.out /tmp/anuenue-seed-B.out; then
    echo "✓ deterministic: same seed → byte-identical output"
else
    echo "✗ non-deterministic — bug?" >&2
    exit 1
fi

# -s and -F are additive (-F is the Ruby-lolcat offset alias).
# These two invocations produce identical output:
echo "AGNOS" | "$ANUENUE" -s 50 -F 50
echo "AGNOS" | "$ANUENUE" -s 100
