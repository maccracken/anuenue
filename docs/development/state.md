# anuenue — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.6.0** — *current.* cut 2026-05-22 (sixth release; second
same-day cut after 0.5.0). **M5 closed.** Performance pass:
three layered optimisations recover the M3 ASCII regression and
overshoot the v0.3.0 floor. ASCII short-circuit + binary-searched
`cp_is_extending` LUT + 1 530-entry phase-cached escape buffer.
End-to-end ASCII no-LF overhead 91.6 → **47.0 ns/byte (−48.7%)**;
UTF-8 mixed 66.3 → 43.0 (−35.1%). DCE binary +1 040 B (the 48 KB
phase table lives on the heap, doesn't bloat the binary). All
four M3 goldens still byte-identical; 26 new tcyr assertions
(146 → 172) lock the cache's per-entry bytes against the runtime
path. New `scripts/perf-bench.sh` is the M5 ratchet — every minor
cut from here forward re-runs it.

**0.5.0** — cut 2026-05-22 (fifth release, first after the four
same-day cuts that landed 0.1.0–0.4.0). **M4 closed.** Animation
mode: `-a` / `-d <secs>` / `-S <speed>`. Buffers stdin once (64 KB
ceiling), pre-tags grapheme clusters with the M3 state machine,
repaints at ~60 fps with phase shifted per frame.
`darshana::tty_cursor_up(n)` (sandhi-bumped 0.5.1 → 0.5.2) re-
anchors the rendered block. Non-blocking signalfd (HUP/INT/TERM)
probed between frames cleans up the cursor on Ctrl-C. Non-animation
invocations byte-identical to v0.4.0 — all four M3 goldens green,
v0.3.0 `-s 100` baseline still green. 42 new tcyr assertions (104
→ 146). New `scripts/animate-smoke.sh` asserts the structural
contract animation can't lock down with a byte-identical golden.

**0.4.0** — cut 2026-05-21 (fourth same-day release). **M3 closed.**
UTF-8 grapheme awareness: filter cycles by cluster, not byte.
Combining marks / ZWJ-extending / regional-indicator pairs all
fold into single clusters. ASCII path stays byte-identical (v0.3.0
`-s 100` golden remains green). Three new corpus goldens (CJK,
combining diacritic, ZWJ + RI flag); 30 new tcyr assertions (74 →
104 total). Invalid UTF-8 → graceful per-byte degradation. Chunk-
boundary carry handles 4 096-byte read splits. vyakarana evaluated
and rejected (wrong domain — source-code tokenizer, not Unicode
database); inline practical-subset classifier ships instead.

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

**M5 (Performance Pass) — shipped at v0.6.0.** Three layered
optimisations recover the M3 cluster-classification regression
and beat the v0.3.0 floor on the canonical ASCII no-LF corpus.

1. **ASCII short-circuit** in `anuenue_filter` and
   `_pretag_clusters` — `b < 0x80` skips `utf8_seq_len` +
   `utf8_decode` + `cp_is_extending` + `cp_is_regional_indicator`,
   honouring the `prev_was_zwj` latch for the ZWJ-then-ASCII
   edge case the M3 semantics preserve.
2. **Binary-searched `cp_is_extending` LUT** — sorted `[lo, hi]`
   pair table + log₂(21) ≈ 5 comparisons + cheap reject for
   `cp < 0x0300` and `cp > 0xE01EF`. Replaces the v0.4.0
   21-condition linear chain. Perf-neutral on ASCII (already
   short-circuited); helps UTF-8-heavy non-Latin corpora.
3. **Phase-cached escape buffer** — 1 530-entry table indexed by
   `phase % ANUENUE_PHASE_MOD` holding pre-formatted
   `\x1b[38;2;R;G;Bm` escapes. Replaces `hsv_rainbow +
   tty_fg_rgb_buf` per cluster with a single length-prefixed
   memcpy. 32-byte stride per entry; heap-allocated at first
   filter/animate entry; doesn't bloat the DCE binary.

Animation mode benefits equally: `_render_frame` routes through
the same `_emit_phase_esc` shared with the filter loop.

`scripts/perf-bench.sh` (new) scriptizes the end-to-end ASCII
per-byte measurement docs/benchmarks.md kept describing manually.
It's the M5 ratchet — every minor cut from here forward re-runs
it.

Next slot is **M6 — Color-Mode Negotiation (v0.7.0)** per
[roadmap.md § M6](roadmap.md#m6--color-mode-negotiation-v070):
TTY detection, `TERM` / `COLORTERM` probing, 24-bit / 256 / 16 /
monochrome fallbacks, `NO_COLOR` honour. Dep gate: darshana's
color-capability probing surface (currently absent — sandhi-unlock
candidate). M5's phase-cached escape buffer is the layer M6 will
swap palettes against; the table just needs additional entries
or a per-mode pointer.

## Toolchain

- **Cyrius pin**: `6.0.1` (in `cyrius.cyml [package].cyrius`).
- Pin-lag spectrum: aligned with darshana 0.5.2 / sakshi 2.2.5 / agnostik 1.2.2 — all on 6.0.1 since scaffold. Re-evaluate at each minor cut; sandhi-bump if a dep ships a 6.0.x+ upgrade we want.

## Source

| File | Lines | Surface |
|------|-------|---------|
| `src/filter.cyr` | ~540 | `ANUENUE_*` constants + **`ANUENUE_ESC_TABLE_ENTRY_SIZE`** (M5). `hsv_rainbow(phase, out_rgb)` integer 6-sector HSV. **M3 (v0.4.0)**: `utf8_seq_len` / `utf8_decode` / `cp_is_extending` / `cp_is_regional_indicator`. **M5 (v0.6.0)**: `cp_is_extending` rewritten as binary search over `_CP_EXT_TABLE` (21 sorted ranges); new `_phase_esc_init()` builds the `_PHASE_ESC_TABLE` (1 530 × 32 B heap; idempotent first-call init); `_emit_phase_esc(line_buf, pos, phase)` replaces the per-cluster `hsv_rainbow + tty_fg_rgb_buf` pair. `anuenue_filter()` adds an ASCII short-circuit branch ahead of the UTF-8 path and routes both branches through `_emit_phase_esc`. |
| `src/animate.cyr` | ~280 | **NEW at M4 (v0.5.0)**. `ANUENUE_ANIMATE_INPUT_MAX` / `_CLUSTER_MAX` / `_FRAME_MS` / `_DEFAULT_DURATION_S` / `_DEFAULT_SPEED` / `_SFD_NONBLOCK` constants. `_animate_slurp_stdin`, `_pretag_clusters` (ASCII short-circuit added at M5), `_count_lf_clusters`, `_input_ends_with_lf`, `_render_frame` (routes through M5's `_emit_phase_esc`), `_open_exit_signalfd`, `_signal_pending`, `anuenue_animate(duration_secs, speed)` (M5: calls `_phase_esc_init()` at startup, shared with filter path). |
| `src/main.cyr` | ~115 | Entrypoint + flag dispatch. args_init / alloc_init / flags context (M4 added -a / -d / -S to the M2 -h/-V/-p/-s/-F set) / argv pack / flags_parse / dispatch to print_version / print_usage / **anuenue_animate or anuenue_filter** (M4 branch). |
| `src/version_str.cyr` | ~18 | **AUTO-GENERATED** by `scripts/version-bump.sh`. Holds `_VERSION_STR_ANUENUE` + `_VERSION_LEN_ANUENUE`. Never hand-edit; CI's Version consistency step asserts the literal matches `VERSION`. |
| `src/test.cyr` | 12 | top-level test entry stub (referenced by `cyrius.cyml [build].test`). Actual tests live in `tests/anuenue.tcyr`. |

The third file the M0 plan anticipated (`src/hsv.cyr`) still
hasn't earned a split — `hsv_rainbow` is ~30 lines and lives in
`filter.cyr`. M3 added the UTF-8 / cluster surface to `filter.cyr`
without crowding it; M4 added a new `animate.cyr` rather than
bloating filter.cyr further (cluster pre-tag + frame loop are a
distinct concern from the streaming filter). M5 (perf pass) may
still pull HSV out into `src/hsv.cyr` if a phase-cached escape
buffer wants to live next to the geometry.

## Binary

- **Size (0.6.0, DCE on)**: **335 160 bytes** (~327 KB). Delta vs
  0.5.0: **+1 040 bytes** for the M5 phase-cache helper fns
  (`_phase_esc_init` / `_emit_phase_esc`) + `cp_is_extending`'s
  LUT init body. The 48 KB phase-cache table lives on the heap
  (one alloc at first filter/animate entry) and is NOT counted
  in the DCE binary — that's why an optimisation of this size
  costs ~1 KB on disk instead of 50 KB.
- **DCE elimination**: 1 251 unreachable fns, 220 732 bytes NOPed.
- **M5 acceptance cap**: 350 KB — comfortably under (−14 840 B
  headroom for M6's color-mode negotiation work).
- **Prior floors**: 0.5.0 = 334 120 B, 0.4.0 = 322 368 B, 0.3.0 = 317 216 B, 0.2.0 = 304 368 B.
- **Output path**: `build/anuenue`

## Tests

| File | Status |
|------|--------|
| `tests/anuenue.tcyr` | **172 assertions across 28 groups**. M1: smoke/HSV/geometry/constants (47). M2: long/short bool, int extraction, attached long-form, additive seed+offset, error variants, version literal (27). M3: utf8_seq_len 1/2/3/4-byte detection, invalid + truncated handling, utf8_decode canonical codepoints, cp_is_extending across ranges, cp_is_regional_indicator bounds (30). M4: animate constants sanity, _pretag_clusters ASCII / combining / CJK / truncated / overflow cap, _count_lf_clusters, _input_ends_with_lf, -a/-d/-S flag parsing (42). **M5: _phase_esc_init idempotency, per-entry byte-identical round-trip against hsv_rainbow + tty_fg_rgb_buf across 8 canonical phases, phase normalization (negative + >MOD), table layout invariants (32-byte stride, 13–19-byte entry length envelope) (26)**. End-to-end stdin/stdout owned by golden harness + animate-smoke + perf-bench. |
| `tests/anuenue.bcyr` | **2 micro-benchmarks** (1M iter each): `hsv_rainbow` ≈8 ns/call, `tty_fg_rgb_buf` ≈45 ns/call. The M5 cut replaced these on the hot path with `_emit_phase_esc` (~10 ns/call); the bcyr still measures the underlying primitives since they remain in the table-build path at startup. |
| `tests/anuenue.fcyr` | fuzz stub — first harness still pending. M5 added a third natural target: random `phase` against `_emit_phase_esc` → no crash, never reads past `_PHASE_ESC_TABLE`'s bounds, returns `pos + elen` consistently. |
| `tests/golden/*.out` | **Four fixtures**: `agnos-rainbow-s100` (M2 ASCII baseline, 238 B), `cjk-mixed-s0` (M3 CJK+ASCII, 125 B), `combining-s0` (M3 é + rainbow, 155 B), `zwj-flag-s0` (M3 ZWJ family + flag, 135 B). All four still byte-identical after M5 — proves the phase-cached escapes match the v0.5.0 runtime path exactly. Asserted by `scripts/golden-check.sh` and CI's **Golden output** step. |
| `scripts/animate-smoke.sh` | M4 (v0.5.0). Animation structural guard. |
| `scripts/perf-bench.sh` | **NEW at M5 (v0.6.0)**. End-to-end ASCII + UTF-8 per-byte overhead measurement. The M5 ratchet — every minor cut from here forward re-runs it. |

Assertion count history: M1 47 → M2 74 (+27) → M3 104 (+30) → M4 146 (+42) → M5 172 (+26).

## Dependencies

Direct (declared in `cyrius.cyml`):

| Dep | Tag | Role | Status |
|-----|-----|------|--------|
| `darshana` | 0.5.2 | ANSI color escape generation (24-bit truecolor added at 0.5.1; **`tty_cursor_up(n)` / `tty_cursor_down(n)` added at 0.5.2** for anuenue's M4 animation re-anchor) | Live. Filter path uses `tty_fg_rgb_buf` + `tty_sgr_reset_buf`; animation path additionally uses `tty_cursor_up`, `tty_cursor_hide`, `tty_cursor_show`, `tty_sgr_reset`. |
| `sakshi` | 2.2.5 | Errors / tracing / structured logging | Standard wiring per first-party-standards |
| `agnostik` | 1.2.2 | Shared Result / Error shapes | Standard wiring |
| Cyrius stdlib | n/a | string, fmt, alloc, io, vec, str, syscalls, assert, bench, args, flags, **chrono (M4)** | Auto-resolved via `cyrius deps`. `args` + `flags` added at M2; `chrono` added at M4 for frame timing (`sleep_ms`) and deadline math (`clock_now_ns`). |

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

- **`docs/adr/0001-pipe-purity.md`** — planned for M7. M4 introduces
  the *first deliberate exception* to the pipe-purity rule:
  animation mode buffers up to 64 KB of stdin before rendering.
  M5 doesn't add a second exception — the phase-cache is a fixed
  startup-time alloc, not input-derived buffering.
- **`tests/anuenue.fcyr`** — fuzz harness stub still empty. Four
  natural targets now: the M2 flag parser (random argv tokens →
  `flags_parse` never crashes), the M3 UTF-8 surface
  (`utf8_seq_len` over arbitrary byte streams), the M4
  `_pretag_clusters` cluster state machine, and **the M5
  `_emit_phase_esc` table lookup** (random phase input → bounded
  write, returns `pos + elen` consistently). Defer until M6 or
  whenever a parse / decode / cluster / table-lookup bug is
  discovered in the wild.
- **DCE binary size after M5** — captured at 0.6.0 cut: 335 160
  bytes (+1 040 B vs 0.5.0). Recapture at every minor cut.
  Headroom against the 350 KB cap: ~15 KB for M6's color-mode
  branching.
- **darshana 0.5.2 surface use** — `tty_cursor_down(n)` shipped
  alongside `tty_cursor_up(n)` for symmetry but anuenue currently
  uses only `_up`. M6 (color-mode) may sandhi-bump darshana
  again for a `tty_caps_detect` (or equivalent) — the right
  moment to drive `tty_cursor_down(n)` adoption is then.
- **Capability surface unchanged at M5** — still
  `read(0)`/`write(1)`/`brk(12)`/`exit(60)` + one-shot `open(2)`/
  `close(3)` for `/proc/self/cmdline`, plus the animation-mode
  delta (`rt_sigprocmask(14)` + `signalfd4(289)` + `nanosleep(35)`).
  M5 added no new syscalls.
- **Phase-cache contract for M6** — `_emit_phase_esc(line_buf,
  pos, phase)` is the layer color-mode negotiation will branch
  against. The current table holds 24-bit truecolor escapes;
  M6 will either swap palettes (one table per mode) or build a
  second 256-color / 16-color / monochrome path. Decision deferred
  until M6 opens.

## Next

See [roadmap.md § M6](roadmap.md#m6--color-mode-negotiation-v070).
