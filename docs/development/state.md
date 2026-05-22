# anuenue — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.4.0** — *current.* cut 2026-05-21 (fourth same-day release with
0.1.0 / 0.2.0 / 0.3.0). **M3 closed.** UTF-8 grapheme awareness:
filter cycles by cluster, not byte. Combining marks / ZWJ-extending /
regional-indicator pairs all fold into single clusters. ASCII path
stays byte-identical (v0.3.0 `-s 100` golden remains green). Three
new corpus goldens (CJK, combining diacritic, ZWJ + RI flag); 30
new tcyr assertions (74 → 104 total). Invalid UTF-8 → graceful
per-byte degradation. Chunk-boundary carry handles 4 096-byte read
splits. vyakarana evaluated and rejected (wrong domain — source-
code tokenizer, not Unicode database); inline practical-subset
classifier ships instead.

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

**M3 (UTF-8 Grapheme Awareness) — shipped at v0.4.0.** Cluster
classification covers combining marks, ZWJ-joined sequences,
regional-indicator pairs, and variation selectors. Invalid UTF-8 →
graceful degradation (per-byte cycling, never panic). Chunk-boundary
handling: partial sequences carry to the next read; EOF with carry
emits remaining bytes as singletons.

Practical-subset classifier vs full UAX #29: ships ~18 combining-
mark ranges + ZWJ + VS + RI. Hangul L/V/T composition and some
Brahmic spacing-mark sequences misclassify as advancing (errs on
"more rainbow, not less"). ADR 0003 (M7) will record the trade.

Next slot is **M4 — Animation Mode (v0.5.0)** per
[roadmap.md](roadmap.md): `-a` / `-d <duration>` / `-S <speed>`
plus cursor positioning + SIGINT handler. Dep gate: darshana::cursor
(already in 0.5.x).

## Toolchain

- **Cyrius pin**: `6.0.1` (in `cyrius.cyml [package].cyrius`)
- Pin-lag spectrum: matches darshana 0.5.0 / sakshi 2.2.5 / agnostik 1.2.2 — all on 6.0.1; no lag at scaffold.

## Source

| File | Lines | Surface |
|------|-------|---------|
| `src/filter.cyr` | ~440 | `ANUENUE_*` constants (phase mod/step/start, line-buf / read-chunk / flush-reserve sizing — flush-reserve bumped 22→32 at M3 for 4-byte codepoints); `hsv_rainbow(phase, out_rgb)` — integer 6-sector HSV. **M3 (v0.4.0)**: `utf8_seq_len(buf, i, n)` returns 1/2/3/4 valid, 0 truncated, 1 invalid; `utf8_decode(buf, i, seqlen)` codepoint assembly; `cp_is_extending(cp)` practical-subset combining-mark classifier; `cp_is_regional_indicator(cp)` flag pair. `anuenue_filter()` cluster-aware loop with three latches (`saw_any`, `prev_was_zwj`, `prev_unpaired_ri`) and chunk-boundary carry. M2 made `ANUENUE_PHASE_STEP` and `ANUENUE_PHASE_START` flag-overridable. |
| `src/main.cyr` | ~110 | Entrypoint + flag dispatch. args_init / alloc_init / flags context (-h/-V/-p/-s/-F) / argv pack / flags_parse / dispatch to print_version / print_usage / anuenue_filter. M2 grew this from ~20 lines (scaffold-shell) to ~110 with the flag surface. |
| `src/version_str.cyr` | ~18 | **AUTO-GENERATED** by `scripts/version-bump.sh`. Holds `_VERSION_STR_ANUENUE` + `_VERSION_LEN_ANUENUE`. Never hand-edit; CI's Version consistency step asserts the literal matches `VERSION`. |
| `src/test.cyr` | 12 | top-level test entry stub (referenced by `cyrius.cyml [build].test`). Actual tests live in `tests/anuenue.tcyr`. |

The third file the M0 plan anticipated (`src/hsv.cyr`) still
hasn't earned a split — `hsv_rainbow` is ~30 lines and lives in
`filter.cyr`. Revisit at M3 (UTF-8 grapheme awareness) if the
grapheme-boundary logic crowds the filter loop.

## Binary

- **Size (0.4.0, DCE on)**: **322 368 bytes** (~315 KB).
  Delta vs 0.3.0: **+5 152 bytes** for the UTF-8 + grapheme-
  classification surface. M5 (perf pass) will set a production
  budget against this floor.
- **DCE elimination**: 1 239 unreachable fns, 218 003 bytes NOPed.
- **Prior floors**: 0.3.0 = 317 216 B, 0.2.0 = 304 368 B.
- **Output path**: `build/anuenue`

## Tests

| File | Status |
|------|--------|
| `tests/anuenue.tcyr` | **104 assertions across 18 groups**. M1: smoke/HSV/geometry/constants (47). M2: long/short bool, int extraction, attached long-form, additive seed+offset, error variants, version literal (27). **M3: utf8_seq_len 1/2/3/4-byte detection, invalid + truncated handling, utf8_decode canonical codepoints, cp_is_extending across ranges, cp_is_regional_indicator bounds (30)**. Cyrius can't trivially redirect fd 0/1 in unit scope, so the end-to-end byte-stream is owned by the golden harness. |
| `tests/anuenue.bcyr` | **2 micro-benchmarks** (1M iter each): `hsv_rainbow` ≈8 ns/call, `tty_fg_rgb_buf` ≈45 ns/call. Captured against the M1 baseline in `docs/benchmarks.md`. |
| `tests/anuenue.fcyr` | fuzz stub — first harness still pending. The M3 UTF-8 surface (`utf8_seq_len` over random byte tokens) is now the natural target since invalid-input handling is documented + tested. |
| `tests/golden/*.out` | **Four fixtures**: `agnos-rainbow-s100` (M2 ASCII baseline, 238 B), `cjk-mixed-s0` (M3 CJK+ASCII, 125 B), `combining-s0` (M3 é + rainbow, 155 B), `zwj-flag-s0` (M3 ZWJ family + flag, 135 B). Asserted by `scripts/golden-check.sh` and CI's **Golden output** step. |

Assertion count history: M1 47 → M2 74 (+27) → M3 104 (+30). M4
(animation) likely adds a small set since cursor + signal handling
resist unit-level testing.

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
- **DCE binary size after M3** — captured at 0.4.0 cut: 322 368
  bytes (+5 152 B vs 0.3.0; +18 000 B vs 0.2.0). Recapture at
  every minor cut.

## Next

See [roadmap.md § M4](roadmap.md#m4--animation-mode-v050).
