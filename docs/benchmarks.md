# anuenue — Benchmarks

> Per-character overhead is the hot-path metric. anuenue sits in MOTD
> pipelines (`iam | anuenue`, `bnrmr | anuenue`), so end-users feel
> the wall-clock cost of one character through the filter on every
> shell login. This file captures the baseline at each release.

## Methodology

Two layers of measurement:

1. **Cyrius `bench` micro** — `tests/anuenue.bcyr`. Per-call cost of
   the two hot-path primitives (`hsv_rainbow` and `tty_fg_rgb_buf`)
   measured with `lib/bench.cyr`'s batched-clock harness (1M iter
   per batch — keeps total wall-time well past the ~120ns
   `clock_gettime` overhead floor).
2. **End-to-end shell** — `cat <fixture> | anuenue > /dev/null` vs
   `cat <fixture> > /dev/null`, measured with shell `time` over
   three runs. The fixture is `base64`-of-1MB-`/dev/urandom` — a
   `~1.4MB` ASCII corpus, no LF compression, all printable bytes.
   *(M1 captures this manually; M5 — perf pass — will scriptize.)*

Host: `archaemenid`-class workstation (AMD Zen, Linux 7.0.x, glibc
n/a — Cyrius bypasses libc).

## v0.2.0 — M1 baseline (2026-05-21)

First end-to-end measurement on the pipe-purity proof. No perf work
yet; the M5 milestone (v0.6.0) will iterate against this baseline.

### Micro

| Primitive             | Avg (ns/call) | Min  | Max  | Iters  |
|-----------------------|---------------|------|------|--------|
| `hsv_rainbow`         |  8            |  8   |  8   | 1M     |
| `tty_fg_rgb_buf`      | 45            | 45   | 45   | 1M     |

Per-character formatting (escape emission) costs ~5.6× the HSV
computation. Not surprising — `_ansi_emit_u8` runs three times per
escape (one per channel) and each invocation does a divide/modulus
chain. M5 candidates: pre-computed 256-entry decimal-byte LUT for
channel encoding; SIMD-batched escape emission once a corpus of
"typical rainbow input" is large enough to justify it.

### End-to-end

Input: `base64 < /dev/urandom` truncated to **1 416 501 bytes** —
pure-ASCII, no embedded LFs at the line-buffer boundary, all bytes
get the truecolor prefix.

| Pipeline                              | Wall (s, mean of 3) | User | Sys  |
|---------------------------------------|---------------------|------|------|
| `cat fixture > /dev/null`             | 0.013               | 0.01 | 0.01 |
| `anuenue < fixture > /dev/null`       | 0.087               | 0.08 | 0.00 |

- **Per-byte overhead**: `(0.087 − 0.013) / 1 416 501 ≈ 53 ns/byte`
- **Output expansion**: `24 660 228 / 1 416 501 ≈ 17.4×` — every
  input byte produces ~17 bytes of fg-escape + the payload byte +
  per-line reset overhead. Matches the worst-case envelope
  `_ansi_emit_u8` + framing (19 max, 13–17 typical) plus a 4-byte
  reset every line.

### Notes

- `hsv_rainbow`'s 8ns is below `clock_gettime`'s per-call overhead;
  the batched harness is the only way to measure it accurately.
- The end-to-end measurement is dominated by `tty_fg_rgb_buf`
  (the 45ns × ~1.4M = ~64ms accounted of the ~74ms anuenue-only
  delta vs cat). The remaining ~10ms is the filter-loop overhead
  (read syscalls, branch dispatch, write syscalls — 32KB flushes,
  so ~43 write(2) calls for 1.4MB input).
- DCE was NOT applied to the M1 binary. Re-measure with
  `CYRIUS_DCE=1 cyrius build ...` at the M5 perf pass.

## Trend

| Release | Per-byte (ns) | hsv_rainbow (ns) | tty_fg_rgb_buf (ns) |
|---------|---------------|------------------|---------------------|
| v0.2.0  | 53            | 8                | 45                  |

Future releases append rows. M5 (v0.6.0) is the perf-pass cut and
sets the per-byte target.
