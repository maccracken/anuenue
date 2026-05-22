#!/bin/sh
# 01 — Hello, rainbow.
#
# Surface: default invocation (no flags). Reads stdin, emits each
# character tinted with a 24-bit ANSI foreground escape, advancing
# the HSV phase by ANUENUE_PHASE_STEP=7 per grapheme cluster.
#
# Expected: the string "AGNOS\n" comes out the right side, each
# letter a different colour — red → orange → yellow → green …
#
# Cite: src/main.cyr (main entry); src/filter.cyr (anuenue_filter).
# ADR: docs/adr/0001-pipe-purity.md (stdin → stdout invariant).

set -eu
ANUENUE=${ANUENUE:-anuenue}

echo "AGNOS" | "$ANUENUE"
