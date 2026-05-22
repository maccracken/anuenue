#!/bin/sh
# 03 — UTF-8 grapheme-cluster-aware cycling.
#
# Surface: M3 (v0.4.0) — anuenue cycles by Unicode grapheme cluster,
# not by byte. Each visible glyph gets exactly one phase advance,
# regardless of how many bytes / codepoints make it up.
#
# Expected behaviour (each line cycles once per *visible character*):
#   - "日本語AGNOS"      — CJK ideographs: one phase per character.
#   - "café"              — combining acute (U+0301): one cluster.
#   - "👨‍👩‍👧"            — ZWJ family emoji: one phase advance.
#   - "🇺🇸 🇯🇵 🇰🇷"        — regional-indicator pairs: one phase per flag.
#
# Cite: src/filter.cyr (utf8_seq_len / utf8_decode /
# cp_is_extending / cp_is_regional_indicator).
# ADR: docs/adr/0003-grapheme-cluster-cycling.md.

set -eu
ANUENUE=${ANUENUE:-anuenue}

printf '%s\n' "日本語AGNOS"      | "$ANUENUE" -s 0
printf '%s\n' "café"             | "$ANUENUE" -s 0
printf '%s\n' "👨‍👩‍👧 family"     | "$ANUENUE" -s 0
printf '%s\n' "🇺🇸 🇯🇵 🇰🇷 flags"  | "$ANUENUE" -s 0
