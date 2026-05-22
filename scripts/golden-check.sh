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

# Fixture: AGNOS-rainbow @ seed=100. Inputs documented inline so
# the fixture is reproducible from this script alone — never rely
# on tribal knowledge of how a committed .out was generated.
EXPECTED="tests/golden/agnos-rainbow-s100.out"
ACTUAL=$(mktemp)
ACTUAL2=$(mktemp)
trap 'rm -f "$ACTUAL" "$ACTUAL2"' EXIT INT TERM

printf "AGNOS rainbow" | "$BIN" -s 100 > "$ACTUAL"
if ! diff -q "$EXPECTED" "$ACTUAL" > /dev/null; then
    echo "golden-check: DRIFT on $EXPECTED" >&2
    echo "Expected ($(wc -c < "$EXPECTED") bytes):" >&2
    xxd "$EXPECTED" | head -3 >&2
    echo "Actual ($(wc -c < "$ACTUAL") bytes):" >&2
    xxd "$ACTUAL" | head -3 >&2
    fail "regenerate with: printf \"AGNOS rainbow\" | ./build/anuenue -s 100 > $EXPECTED"
fi
pass "$EXPECTED — bytes match (-s 100 produces $(wc -c < "$EXPECTED") bytes)"

# Determinism: same invocation twice must produce byte-identical
# output. Catches accidental introduction of non-determinism (RNG,
# time, environment) that the single golden diff would let through.
printf "AGNOS rainbow" | "$BIN" -s 100 > "$ACTUAL2"
diff -q "$ACTUAL" "$ACTUAL2" > /dev/null \
    || fail "non-deterministic: two runs with the same seed produced different output"
pass "determinism — two runs with -s 100 are byte-identical"

echo
echo "golden-check: PASS"
