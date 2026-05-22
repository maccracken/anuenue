# anuenue — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.3.0** — cut 2026-05-21 (open + close compressed, third same-day
release with 0.1.0 / 0.2.0). **M2 closed.** Five-flag CLI
(`-h`/`-V`/`-p`/`-s`/`-F`) sits between argv and the M1 filter loop;
loop itself byte-identical to 0.2.0. Determinism is now a
CI-asserted property; version literal is auto-generated; capability
surface picked up open/close at startup for /proc/self/cmdline.

**0.2.0** — cut 2026-05-21. **M1 closed.** Pipe-purity proof
shipped: stdin → stdout per-byte 24-bit rainbow via darshana 0.5.1's
new `tty_fg_rgb_buf` + `tty_sgr_reset_buf` helpers. Drove the
darshana truecolor unlock as the sandhi consumer; both repos cut
same-day.

**0.1.0** — scaffolded 2026-05-21 via `cyrius init anuenue`. Empty
filter — pure scaffold release.

## Phase

**M2 closed at v0.3.0.** Next slot is **M3 — UTF-8 Grapheme
Awareness (v0.4.0)** per [roadmap.md](roadmap.md): cycle by
grapheme cluster, not byte. Multi-byte UTF-8 characters (and
combining sequences, ZWJ emoji) get one phase advance, not N.

## Toolchain

- **Cyrius pin**: `6.0.1` (in `cyrius.cyml [package].cyrius`)
- Pin-lag spectrum: matches darshana 0.5.0 / sakshi 2.2.5 / agnostik 1.2.2 — all on 6.0.1; no lag at scaffold.

## Source

| File | Lines | Surface |
|------|-------|---------|
| `src/filter.cyr` | ~190 | `ANUENUE_*` constants (phase mod, phase step, phase start, line-buf / read-chunk / flush-reserve sizing); `hsv_rainbow(phase, out_rgb)` — integer 6-sector HSV; `anuenue_filter()` — stdin→stdout loop with LF-flush + force-flush. Library surface; testable in isolation. M2 made `ANUENUE_PHASE_STEP` and `ANUENUE_PHASE_START` flag-overridable (mutable, written from main before filter runs). |
| `src/main.cyr` | ~110 | Entrypoint + flag dispatch. args_init / alloc_init / flags context (-h/-V/-p/-s/-F) / argv pack / flags_parse / dispatch to print_version / print_usage / anuenue_filter. M2 grew this from ~20 lines (scaffold-shell) to ~110 with the flag surface. |
| `src/version_str.cyr` | ~18 | **AUTO-GENERATED** by `scripts/version-bump.sh`. Holds `_VERSION_STR_ANUENUE` + `_VERSION_LEN_ANUENUE`. Never hand-edit; CI's Version consistency step asserts the literal matches `VERSION`. |
| `src/test.cyr` | 12 | top-level test entry stub (referenced by `cyrius.cyml [build].test`). Actual tests live in `tests/anuenue.tcyr`. |

The third file the M0 plan anticipated (`src/hsv.cyr`) still
hasn't earned a split — `hsv_rainbow` is ~30 lines and lives in
`filter.cyr`. Revisit at M3 (UTF-8 grapheme awareness) if the
grapheme-boundary logic crowds the filter loop.

## Binary

- **Size (0.3.0, DCE on)**: **317 216 bytes** (~310 KB) from a clean
  `rm -rf build && cyrius deps && CYRIUS_DCE=1 cyrius build`.
  Delta vs 0.2.0: **+12 848 bytes** for the args + flags stdlib
  modules + version_str. M5 (perf pass) will set a production
  budget against this floor.
- **DCE elimination**: 1 239 unreachable fns, 217 727 bytes NOPed.
- **Prior floors**: 0.2.0 = 304 368 bytes (1 236 fns NOPed).
- **Output path**: `build/anuenue`

## Tests

| File | Status |
|------|--------|
| `tests/anuenue.tcyr` | **74 assertions across 13 groups** (smoke; HSV canonical hues; HSV sector ramps; HSV phase normalization; filter-geometry flush-reserve sizing; filter-constant sanity; **M2 flags**: long/short bool, short -V, int -p/-s/-F, --freq=N attached, additive seed+offset, error variants UNKNOWN/MISSING_VALUE/BAD_INT, version literal shape). Cyrius can't trivially redirect fd 0/1 in unit scope, so the end-to-end byte-stream is owned by the golden harness. |
| `tests/anuenue.bcyr` | **2 micro-benchmarks** (1M iter each): `hsv_rainbow` ≈8 ns/call, `tty_fg_rgb_buf` ≈45 ns/call. Captured against the M1 baseline in `docs/benchmarks.md`. |
| `tests/anuenue.fcyr` | fuzz stub — first harness still pending; the M2 flag parser is now the natural target. |
| `tests/golden/agnos-rainbow-s100.out` | **238-byte fixture** for `printf "AGNOS rainbow" \| anuenue -s 100`. Drift = regression in filter / HSV / darshana. Asserted by `scripts/golden-check.sh` and CI's **Golden output** step. |

Assertion target M2: doubled (74 vs M1's 47). M3 will add UTF-8
corpus coverage on top.

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
  implementation already enforces the pipe-purity rule and the M2
  flag surface holds the line (no file-input flag, no config
  file, no themes); the ADR records the *why* before later
  milestones could tempt scope creep.
- **`tests/anuenue.fcyr`** — fuzz harness stub still empty. The
  M2 flag parser is now the natural target (random argv tokens →
  flags_parse never crashes / always exits with a valid status).
  Defer until M3 or whenever a parse-path bug is discovered in the
  wild.
- **DCE binary size after M2** — captured at 0.3.0 cut: 317 216
  bytes (+12.8 KB vs 0.2.0). Recapture at every minor cut.

## Next

See [roadmap.md § M3](roadmap.md#m3--utf-8-grapheme-awareness-v040).
