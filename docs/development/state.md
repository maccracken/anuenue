# anuenue — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.2.0** — cut 2026-05-21 (open + close compressed, same day as the
0.1.0 scaffold). **M1 closed.** Pipe-purity proof shipped: stdin →
stdout per-byte 24-bit rainbow via darshana 0.5.1's new
`tty_fg_rgb_buf` + `tty_sgr_reset_buf` helpers. Drove the darshana
truecolor unlock as the sandhi consumer; both repos cut same-day.

**0.1.0** — scaffolded 2026-05-21 via `cyrius init anuenue`. Empty
filter — pure scaffold release; the M1 implementation work lives
in the 0.2.0 section above.

## Phase

**M1 closed at v0.2.0.** Next slot is **M2 — Flag Surface (v0.3.0)**
per [roadmap.md](roadmap.md): `-s <seed>`, `-p <freq>`, `-h`, `-V`,
`-F <offset>`.

## Toolchain

- **Cyrius pin**: `6.0.1` (in `cyrius.cyml [package].cyrius`)
- Pin-lag spectrum: matches darshana 0.5.0 / sakshi 2.2.5 / agnostik 1.2.2 — all on 6.0.1; no lag at scaffold.

## Source

M1 shipped the predicted module split (the test suite needed the
filter without its top-level `main()` call):

| File | Lines | Surface |
|------|-------|---------|
| `src/filter.cyr` | ~180 | `ANUENUE_*` constants (phase mod, phase step, line-buf / read-chunk / flush-reserve sizing); `hsv_rainbow(phase, out_rgb)` — integer 6-sector HSV; `anuenue_filter()` — stdin→stdout loop with LF-flush + force-flush. Library surface; testable in isolation. |
| `src/main.cyr` | ~20 | Entrypoint shell: `include "src/filter.cyr"` + `fn main()` (alloc_init + `anuenue_filter()`) + top-level `var r = main(); syscall(SYS_EXIT, r);`. |
| `src/test.cyr` | 12 | top-level test entry stub (referenced by `cyrius.cyml [build].test`). Actual tests live in `tests/anuenue.tcyr`. |

The third file the M0 plan anticipated (`src/hsv.cyr`) didn't earn
a split — `hsv_rainbow` is ~30 lines and lives in `filter.cyr`. Revisit
at M3 (UTF-8 grapheme awareness) if the grapheme-boundary logic
crowds the filter loop.

## Binary

- **Size (0.2.0, DCE on)**: **304 368 bytes** (~297 KB) from a clean
  `rm -rf build && cyrius deps && CYRIUS_DCE=1 cyrius build`.
  Reference floor for future minor-cycle comparison; M5 (perf pass)
  will set a production budget against this number.
- **DCE elimination**: 1 236 unreachable fns, 217 823 bytes NOPed.
- **Output path**: `build/anuenue`

## Tests

| File | Status |
|------|--------|
| `tests/anuenue.tcyr` | **47 assertions across 6 groups** (smoke; HSV canonical hues; HSV sector ramps; HSV phase normalization; filter-geometry flush-reserve sizing; filter-constant sanity). The end-to-end stdin/stdout filter is exercised manually + via the M1-baseline `docs/benchmarks.md` run; Cyrius can't trivially redirect fd 0/1 inside a unit test, so the I/O surface is owned by integration smoke. |
| `tests/anuenue.bcyr` | **2 micro-benchmarks** (1M iter each): `hsv_rainbow` ≈8 ns/call, `tty_fg_rgb_buf` ≈45 ns/call. Captured against the M1 baseline in `docs/benchmarks.md`. |
| `tests/anuenue.fcyr` | fuzz stub — first harness lands at M2+ when the flag parser exists. |

Assertion target now: 20+ achieved (47). M2 will roughly double it
(flag-parser coverage + `-s seed` determinism asserts).

## Dependencies

Direct (declared in `cyrius.cyml`):

| Dep | Tag | Role | Status |
|-----|-----|------|--------|
| `darshana` | 0.5.1 | ANSI color escape generation (incl. **24-bit truecolor** added at 0.5.1 for anuenue's M1) | Live. Uses `tty_fg_rgb_buf` + `tty_sgr_reset_buf` in the line-buffer composition path. |
| `sakshi` | 2.2.5 | Errors / tracing / structured logging | Standard wiring per first-party-standards |
| `agnostik` | 1.2.2 | Shared Result / Error shapes | Standard wiring |
| Cyrius stdlib | n/a | string, fmt, alloc, io, vec, str, syscalls, assert, bench | Auto-resolved via `cyrius deps` |

No pre-release / pre-1.0 deps on the critical path. No external (non-AGNOS) deps.

## Verification Hosts

| Host | Role | Status |
|------|------|--------|
| `archaemenid` (Beelink SER, AMD Zen) | Primary dev box; will be the iron-soak target once AGNOS userland boots there | Not yet (anuenue runs on host Linux for now) |
| Host Linux (CI runner pattern) | Build + test gate via `.github/workflows/ci.yml` | Active from M0 |

## Consumers

_None yet._

Anticipated at v0.7+:
- `agnoshi` — MOTD pipeline composition
- `iam` — default login splash chain (`iam | anuenue`)
- end-user shells — bash / zsh / agnoshi interactive use

## Carry-Forward

- **`docs/adr/0001-pipe-purity.md`** — planned for M7. The M1
  implementation already enforces the pipe-purity rule (alloc-then-
  read-write-only); the ADR records the *why* before M2 starts
  adding flags that could tempt scope creep (file-input mode, etc.).
- **Integration smoke harness** — Cyrius can't redirect fd 0/1 inside
  a unit test, so the M1 end-to-end coverage is shell-driven (manual
  `printf | anuenue` runs documented in `docs/benchmarks.md`). M2 or
  M5 should land a `scripts/smoke.sh` equivalent to darshana's, with
  golden-output fixtures keyed off the deterministic `-s seed` flag.
- **DCE binary-size budget** — currently unmeasured (M1 build is
  non-DCE). Capture at the next clean build with `CYRIUS_DCE=1`.

## Next

See [roadmap.md § M2](roadmap.md#m2--flag-surface-v030).
