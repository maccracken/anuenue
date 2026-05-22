#!/bin/sh
# golden-check.sh — determinism guard.
#
# The `-s <seed>` flag is the project's deterministic-output hook
# (M2 acceptance criterion: "deterministic-seed test passes"). This
# script regenerates each golden fixture in `tests/golden/` from
# its documented input + flag combination and diffs against the
# committed bytes. Any drift = a regression in the filter loop,
# the HSV geometry, or darshana's escape format.
#
# Run from the repo root:
#
#   sh scripts/golden-check.sh
#
# To accept a deliberate change (e.g. M3's UTF-8 grapheme awareness
# will legitimately alter per-character phase advance), regenerate
# the fixtures and document the visual change in the CHANGELOG.

set -eu

BIN="${BIN:-build/anuenue}"
if [ ! -x "$BIN" ]; then
    echo "golden-check: $BIN not executable — run 'cyrius build src/main.cyr build/anuenue' first" >&2
    exit 1
fi

fail() { echo "golden-check: FAIL — $1" >&2; exit 1; }
pass() { echo "  ok: $1"; }

# Each fixture is reproducible from the inline command below —
# never rely on tribal knowledge of how a committed .out was
# generated. Add fixtures by appending another check_golden call.
ACTUAL=$(mktemp)
ACTUAL2=$(mktemp)
trap 'rm -f "$ACTUAL" "$ACTUAL2"' EXIT INT TERM

# check_golden <expected-path> <description> <regenerate-command>
# The 3rd arg is `sh -c`-able and writes its output to $ACTUAL.
check_golden() {
    expected="$1"
    desc="$2"
    cmd="$3"
    sh -c "$cmd" > "$ACTUAL"
    if ! diff -q "$expected" "$ACTUAL" > /dev/null; then
        echo "golden-check: DRIFT on $expected ($desc)" >&2
        echo "Expected ($(wc -c < "$expected") bytes):" >&2
        xxd "$expected" | head -3 >&2
        echo "Actual ($(wc -c < "$ACTUAL") bytes):" >&2
        xxd "$ACTUAL" | head -3 >&2
        fail "regenerate with: $cmd > $expected"
    fi
    pass "$expected — bytes match ($desc, $(wc -c < "$expected") bytes)"
}

# Fixture 1 — v0.3.0 M2 baseline. ASCII path, default phase
# step, seed=100. Diff against this catches regressions in HSV
# geometry, escape framing, or the M3 cluster loop's ASCII
# fast path.
check_golden "tests/golden/agnos-rainbow-s100.out" \
    "M2 baseline: ASCII -s 100" \
    "printf 'AGNOS rainbow' | $BIN -s 100"

# Fixture 2 — v0.4.0 M3 CJK. Two 3-byte CJK codepoints + ASCII.
# Each CJK char is one cluster → one phase advance per char,
# matching the byte-level rainbow cadence (one fg escape every
# codepoint, three payload bytes per).
check_golden "tests/golden/cjk-mixed-s0.out" \
    "M3 CJK + ASCII -s 0" \
    "printf '日本AGNOS' | $BIN -s 0"

# Fixture 3 — v0.4.0 M3 combining diacritic. \"é\" as base 'e'
# + combining acute U+0301 (two codepoints, one grapheme). Both
# bytes render under a single fg escape; phase advances only when
# the next non-extending codepoint arrives.
#
# NOTE: escapes use POSIX-octal `\NNN`, not `\xHH`. CI runs under
# dash (Ubuntu /bin/sh), which only supports the octal form;
# `\xCC\x81` would be emitted as literal ASCII chars and the
# fixture would drift to a longer per-byte rainbow. \314\201 is
# UTF-8 for U+0301 COMBINING ACUTE ACCENT.
check_golden "tests/golden/combining-s0.out" \
    "M3 combining diacritic é + rainbow" \
    "printf 'e\314\201rainbow' | $BIN -s 0"

# Fixture 4 — v0.4.0 M3 ZWJ + regional indicator. Family emoji
# (👨 ZWJ 👩 ZWJ 👧) renders as ONE grapheme cluster (5 codepoints
# → one phase advance). 🇺🇸 (two regional indicators) also one
# cluster. Stresses both the ZWJ-extending latch and the RI-pair
# latch in one input. \342\200\215 = UTF-8 for U+200D ZWJ
# (octal form per the dash-portability note on Fixture 3).
check_golden "tests/golden/zwj-flag-s0.out" \
    "M3 ZWJ family + RI flag" \
    "printf '👨\342\200\215👩\342\200\215👧🇺🇸' | $BIN -s 0"

# Determinism cross-check: same invocation twice must produce
# byte-identical output. Catches accidental non-determinism (RNG,
# time, environment) that the single-fixture diff would let pass.
printf "AGNOS rainbow" | "$BIN" -s 100 > "$ACTUAL"
printf "AGNOS rainbow" | "$BIN" -s 100 > "$ACTUAL2"
diff -q "$ACTUAL" "$ACTUAL2" > /dev/null \
    || fail "non-deterministic: two runs with the same seed produced different output"
pass "determinism — two runs with -s 100 are byte-identical"

echo
echo "golden-check: PASS"
