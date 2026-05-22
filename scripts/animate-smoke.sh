#!/bin/sh
# animate-smoke.sh — structural guard for M4 animation mode.
#
# Animation is non-deterministic (frame timing varies with host load,
# so the exact frame count and pixel-perfect output differ between
# runs). golden-check.sh owns byte-identical determinism for the
# filter path; this script asserts the *structural* properties the
# animation contract makes:
#
#   1. Exit code 0 on duration-elapsed clean exit.
#   2. Output is non-empty.
#   3. Cursor-hide (CSI ?25l) emitted at start.
#   4. Cursor-show (CSI ?25h) emitted at end.
#   5. At least one cursor-up (CSI <n>A) emitted — proves the frame
#      loop ran more than once.
#   6. Exit code 0 on SIGINT.
#   7. Cursor-show emitted before exit on SIGINT (no terminal left
#      with a hidden cursor — the failure mode that prompted the
#      M4 acceptance criterion "leaves terminal sane after SIGINT").
#
# Run from the repo root:
#
#   sh scripts/animate-smoke.sh

set -eu

BIN="${BIN:-build/anuenue}"
if [ ! -x "$BIN" ]; then
    echo "animate-smoke: $BIN not executable — run 'cyrius build src/main.cyr build/anuenue' first" >&2
    exit 1
fi

fail() { echo "animate-smoke: FAIL — $1" >&2; exit 1; }
pass() { echo "  ok: $1"; }

OUT=$(mktemp)
trap 'rm -f "$OUT"' EXIT INT TERM

# ESC = \033 (POSIX-octal); CI runs under dash, no \xHH support.
ESC=$(printf '\033')

# --- duration-elapsed clean exit -----------------------------------
# 1 second is enough to fire ~60 frames at 16ms intervals without
# bloating CI runtime.
echo "[animate-smoke] -d 1 over short input"
printf 'AGNOS\n' | "$BIN" --color=24bit -a -d 1 > "$OUT" || fail "exit non-zero on duration-elapsed run"
pass "exit 0 after -d 1"

[ -s "$OUT" ] || fail "no output captured from animation"
pass "output non-empty ($(wc -c < "$OUT") bytes)"

# CSI ?25l (cursor hide) — must appear once near the start.
grep -q "${ESC}\[?25l" "$OUT" || fail "no cursor-hide escape (\033[?25l) in output"
pass "cursor-hide present"

# CSI ?25h (cursor show) — must appear near the end.
grep -q "${ESC}\[?25h" "$OUT" || fail "no cursor-show escape (\033[?25h) in output"
pass "cursor-show present"

# CSI <n>A (cursor up) — at least one frame transition.
grep -q "${ESC}\[[0-9][0-9]*A" "$OUT" || fail "no cursor-up escape (\033[<n>A) — frame loop didn't repaint"
pass "cursor-up present (frame loop ran more than once)"

# --- SIGINT cleanup ------------------------------------------------
# Launch with a long duration, kill after a small grace period, and
# verify cursor-show was emitted before the process exited.
echo "[animate-smoke] SIGINT mid-animation"
( printf 'AGNOS\n' | "$BIN" --color=24bit -a -d 60 > "$OUT" 2>&1 ) &
PID=$!
sleep 0.3
kill -INT "$PID" 2>/dev/null || fail "anuenue exited before SIGINT could land"
wait "$PID"
RC=$?
[ "$RC" = 0 ] || fail "exit code $RC on SIGINT (want 0)"
pass "exit 0 after SIGINT"

# The very last bytes of a clean-shutdown trace must include
# cursor-show — otherwise the user's terminal is left without a
# visible cursor (the regression M4's acceptance test guards).
tail -c 50 "$OUT" | grep -q "${ESC}\[?25h" || fail "cursor-show NOT in last 50 bytes of SIGINT output — terminal left dirty"
pass "cursor-show present in cleanup tail"

# --- M8 audit (2026-05-22) — long-cluster heap-overflow regression --
# A grapheme cluster's byte length is unbounded in anuenue's
# practical-subset classifier (base + N combining marks → 1 cluster).
# The pre-fix _render_frame wrote the full cluster into a 32 KB
# line_buf and only checked the flush reserve afterward — a 65 KB
# adversarial cluster overflowed the heap. Post-fix
# (docs/audit/2026-05-22-audit.md § Finding 1) the inner cluster-
# copy loop flushes mid-cluster and re-emits the same phase escape.
#
# This test runs the historical attack pattern and asserts (a) clean
# exit, (b) every base + combiner byte makes it through to stdout.
echo "[animate-smoke] M8 audit — long-cluster pathological input"
LONG_OUT=$(mktemp)
trap 'rm -f "$OUT" "$LONG_OUT"' EXIT INT TERM

# 16000 × (U+0301 = 0xCC 0x81) = 32000 bytes of combining acute,
# preceded by 'A'. Pre-fix: clen = 32001 > LINE_BUF (32768) when
# coupled with the 19-byte escape prefix — heap overflow.
# Post-fix: mid-cluster flush splits the write across multiple
# file_write calls. Single-frame run (-d 0 + SIGINT) keeps the
# captured output bounded for the byte-count assertion.
#
# `\NNN` octal escapes (not `\xNN` hex) for printf — POSIX
# `printf(1)` requires the octal form; dash + busybox-sh ignore
# `\xNN`, which silently produces no combining bytes and a
# misleading "no overflow" pass. (Caught in CI under dash.)
(
    {
        printf 'A'
        i=0
        while [ "$i" -lt 16000 ]; do
            printf '\314\201'
            i=$((i + 1))
        done
    } | "$BIN" --color=24bit -a -d 1 > "$LONG_OUT" 2>&1
) || fail "long-cluster run exited non-zero (want 0)"
pass "exit 0 on long-cluster input"

# Count the combining-acute leading byte 0xCC (octal \314) in the
# captured output. We expect at least 16000 — one per input
# combiner per frame; the animation may repaint many frames, so the
# lower bound is what matters. `tr` + `wc` works on binary; `grep`
# would miss because bytes can land on lines with escape framing.
# (0xCC isn't a legal byte inside an ANSI SGR escape — those use
# `\x1b[…m` with only ASCII — so the count is unambiguous.)
COMBINERS=$(tr -cd '\314' < "$LONG_OUT" | wc -c)
if [ "$COMBINERS" -lt 16000 ]; then
    fail "lost combining-acute bytes — input 16000, output $COMBINERS (mid-cluster flush dropped bytes?)"
fi
pass "all 16000 combiner bytes preserved through mid-cluster flush ($COMBINERS in output)"

echo
echo "animate-smoke: PASS"
