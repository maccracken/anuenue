# anuenue — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.7.0** — *current.* cut 2026-05-22 (seventh release; third
same-day cut). **M6 closed.** Color-mode negotiation:
TRUECOLOR / 256-color / 16-color / MONO selected at startup from a
priority chain — `--color <mode>` override → `--no-color` →
`NO_COLOR` env → stdout-not-TTY (unless `--force-color`) → COLORTERM
→ TERM. M6 acceptance held: `NO_COLOR=1 echo X | anuenue` is byte-
identical to `echo X`. New module `src/color.cyr` (~200 lines)
with mode detection, RGB quantization (xterm 256-cube + bright-16),
and the MONO passthrough. Truecolor perf is unchanged (the M5
phase-cache shape stays the same; only per-entry bytes vary). 69
new tcyr assertions (172 → 241); two new golden fixtures
(`agnos-rainbow-256-s100.out` 160 B, `agnos-rainbow-16-s100.out`
82 B); three NO_COLOR equivalence checks in golden-check.sh.

**0.6.0** — cut 2026-05-22 (sixth release; second same-day cut
after 0.5.0). **M5 closed.** Performance pass: three layered
optimisations recover the M3 ASCII regression and overshoot the
v0.3.0 floor. ASCII short-circuit + binary-searched
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

**M6 (Color-Mode Negotiation) — shipped at v0.7.0.** Four-mode
taxonomy (MONO / COLOR_16 / COLOR_256 / TRUECOLOR) selected by a
priority chain at startup. New `src/color.cyr` owns the mode
enum, override-string parser, RGB → 256-cube quantization, RGB →
bright-16 quantization, `anuenue_detect_color_mode`, and
`anuenue_passthrough` (the MONO bypass). Three new flags wire
into main.cyr: `--no-color`, `--force-color`, `--color <mode>`.
M5's phase-cache becomes mode-aware — the 1 530-entry table holds
per-mode escape bytes; the hot-path emit (`_emit_phase_esc`) is
unchanged because its memcpy is byte-shape-agnostic.

**Dep gate**: darshana 0.5.3 (sandhi in flight) will ship
`tty_isatty(fd)`, `tty_sgr_buf(buf, pos, code)`, `tty_fg_256_buf(
buf, pos, n)`. anuenue M6 ships with three stand-ins
(`_isatty_compat`, `_sgr_buf_compat`, `_fg_256_buf_compat`) in
`src/color.cyr`, marked `TODO(sandhi 0.5.3)`. When 0.5.3 lands,
the swap is mechanical and recovers ~1-2 KB binary.

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

Next slot is **M7 — Public-Surface Freeze + Guide Docs (v0.8.0)**
per [roadmap.md § M7](roadmap.md#m7--public-surface-freeze--guide-docs-v080):
ADR 0001 (pipe-purity), ADR 0002 (HSV inline not abaco), ADR 0003
(grapheme cluster cycling). `docs/guides/integrating-anuenue.md`.
`docs/examples/`. Every flag documented; every public symbol cited
from at least one example. No dep gate; pure documentation work,
the bridge between M6's behavioural surface and M8's audit.

## Toolchain

- **Cyrius pin**: `6.0.1` (in `cyrius.cyml [package].cyrius`).
- Pin-lag spectrum: aligned with darshana 0.5.2 / sakshi 2.2.5 / agnostik 1.2.2 — all on 6.0.1 since scaffold. Re-evaluate at each minor cut; sandhi-bump if a dep ships a 6.0.x+ upgrade we want.

## Source

| File | Lines | Surface |
|------|-------|---------|
| `src/color.cyr` | ~200 | **NEW at M6 (v0.7.0)**. Color mode enum (`ANUENUE_COLOR_MONO`/`_16`/`_256`/`_TRUE`); override-string parser + enum mapping (`_color_override_from_str` / `_color_mode_from_override`); RGB quantization (`_channel_to_6`, `_rgb_to_256` xterm cube; `_rgb_to_16` bright-palette); `anuenue_detect_color_mode(no_color, force_color, override)` reading getenv + the `_isatty_compat` stand-in; `anuenue_passthrough()` MONO bypass (read/write loop, no escapes). Three darshana-0.5.3-pending stand-ins (`_isatty_compat`, `_fg_256_buf_compat`, `_sgr_buf_compat`) marked `TODO(sandhi 0.5.3)`. |
| `src/filter.cyr` | ~545 | `ANUENUE_*` constants + **`ANUENUE_ESC_TABLE_ENTRY_SIZE`** (M5). `hsv_rainbow(phase, out_rgb)` integer 6-sector HSV. M3: `utf8_seq_len` / `utf8_decode` / `cp_is_extending` (M5: binary-searched LUT) / `cp_is_regional_indicator`. M5: `_phase_esc_init()` / `_emit_phase_esc()` / `_PHASE_ESC_TABLE` (1 530 × 32 B heap; idempotent). **M6 (v0.7.0)**: `_phase_esc_init` branches on `ANUENUE_COLOR_MODE` to populate the table with per-mode escapes (TRUECOLOR via darshana's `tty_fg_rgb_buf`, 256 via compat stand-in, 16 via compat stand-in). `anuenue_filter()` keeps the M5 hot path; ASCII short-circuit unchanged. |
| `src/animate.cyr` | ~280 | M4 surface (animation: slurp + pretag + frame loop + signalfd). M5: ASCII short-circuit in `_pretag_clusters`; `_render_frame` routes through `_emit_phase_esc`; `_phase_esc_init` shared with filter. M6: animation also benefits from per-mode escapes via the same path; MONO never reaches animation (main.cyr dispatches to passthrough first). |
| `src/main.cyr` | ~135 | Entrypoint + flag dispatch. args_init / alloc_init / flags context (M6 added `-n` / `-C` / `-c` to the M2/M4 sets) / argv pack / flags_parse / **M6 colour-mode detect step writes `ANUENUE_COLOR_MODE`**; dispatch to print_version / print_usage / **anuenue_passthrough (MONO) or anuenue_animate (-a) or anuenue_filter**. |
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

- **Size (0.7.0, DCE on)**: **349 832 bytes** (~342 KB). Delta vs
  0.6.0: **+14 672 bytes** for the M6 color module + flag wiring +
  stdlib pulls (`streq`, `strstr`, `getenv`). 168 B headroom under
  the M5-set cap of 350 KB; darshana 0.5.3 sandhi will recover
  ~1-2 KB when the three stand-ins go.
- **DCE elimination**: 1 240 unreachable fns, 219 392 bytes NOPed.
- **Cap discipline for M7+**: the 350 KB cap was an M5 acceptance
  number; M7 closeout should raise it to 512 KB to give clear
  runway through v1.0 without changing the gate's role.
- **Prior floors**: 0.6.0 = 335 160 B, 0.5.0 = 334 120 B, 0.4.0 = 322 368 B, 0.3.0 = 317 216 B, 0.2.0 = 304 368 B.
- **Output path**: `build/anuenue`

## Tests

| File | Status |
|------|--------|
| `tests/anuenue.tcyr` | **241 assertions across 34 groups**. M1: smoke/HSV/geometry/constants (47). M2: flags (27). M3: utf8_seq_len/decode/cp_is_extending/cp_is_regional_indicator (30). M4: animate constants + _pretag_clusters + _count_lf_clusters + _input_ends_with_lf + -a/-d/-S flag parsing (42). M5: phase-cache idempotency, byte-identical round-trip, phase normalization, table layout (26). **M6 (v0.7.0): mode enum + override parser (alias coverage) + `_channel_to_6` bucket boundaries (5 thresholds) + `_rgb_to_256` canonical hues + `_rgb_to_16` bright-palette quantization + `_fg_256_buf_compat`/`_sgr_buf_compat` escape framing + bounds rejection (69)**. End-to-end behaviour owned by golden + animate-smoke + perf-bench. |
| `tests/anuenue.bcyr` | 2 micro-benchmarks: `hsv_rainbow` ≈8 ns/call, `tty_fg_rgb_buf` ≈45 ns/call. Pre-M5 the filter loop called both per cluster; M5+ uses `_emit_phase_esc` (~10 ns/call) instead. The micros still measure the table-build path. |
| `tests/anuenue.fcyr` | fuzz stub — first harness still pending. Targets: M2 flag parser, M3 UTF-8 surface, M4 `_pretag_clusters`, M5 `_emit_phase_esc`, and (M6) `_rgb_to_256` / `_rgb_to_16` over random RGB triples. |
| `tests/golden/*.out` | **Six fixtures**. M2/M3: `agnos-rainbow-s100` (238 B), `cjk-mixed-s0` (125 B), `combining-s0` (155 B), `zwj-flag-s0` (135 B). **M6: `agnos-rainbow-256-s100.out` (160 B), `agnos-rainbow-16-s100.out` (82 B)**. All six byte-identical across the M5/M6 cuts — proves the mode-aware phase cache matches runtime exactly. Plus three MONO equivalence checks in golden-check.sh (`NO_COLOR=1 anuenue` / `--no-color` / `--color=none` all byte-identical to input). |
| `scripts/animate-smoke.sh` | M4 (v0.5.0). Animation structural guard. M6: invokes with `--color=24bit` so the TTY-detection in M6 doesn't drop the test into MONO. |
| `scripts/perf-bench.sh` | M5 (v0.6.0). End-to-end ASCII + UTF-8 per-byte overhead. M6: invokes with `--color=24bit` for the same reason. The M5 ratchet. |

Assertion count history: M1 47 → M2 74 (+27) → M3 104 (+30) → M4 146 (+42) → M5 172 (+26) → M6 241 (+69).

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

- **darshana 0.5.3 sandhi** in flight (3rd turn). Will ship
  `tty_isatty(fd)`, `tty_sgr_buf(buf, pos, code)`,
  `tty_fg_256_buf(buf, pos, n)`. anuenue M6 inlines those as
  `_isatty_compat` / `_sgr_buf_compat` / `_fg_256_buf_compat`
  in `src/color.cyr` (marked `TODO(sandhi 0.5.3)`). When 0.5.3
  lands: bump pin, delete the 3 stand-ins, sed call sites.
  Recovers ~1-2 KB binary.
- **`docs/adr/0001-pipe-purity.md`** — planned for M7. M4
  introduced the first exception (animation buffers ≤64 KB stdin).
  M6 adds a second: MONO is a pure passthrough that bypasses the
  filter loop entirely. The ADR now covers the rule + two
  deliberate exceptions.
- **`tests/anuenue.fcyr`** — fuzz harness stub still empty. Now
  five natural targets: M2 flag parser, M3 UTF-8 surface, M4
  `_pretag_clusters`, M5 `_emit_phase_esc`, **and (M6)
  `_rgb_to_256` / `_rgb_to_16`** over random RGB triples (never
  crash, always return a valid escape code). Defer until M7 or a
  parse/decode/cluster/table/quantization bug is observed.
- **DCE binary size after M6** — captured at 0.7.0 cut: 349 832
  bytes (+14 672 B vs 0.6.0; 168 B headroom against the 350 KB
  M5 cap). M7 closeout should raise the cap to 512 KB.
- **Capability surface delta at M6** — adds open/read/close on
  `/proc/self/environ` (getenv lookups at startup; one for
  NO_COLOR, two for COLORTERM/TERM). Net capability set:
  read(0)/write(1)/brk(12)/exit(60)/open(2)/close(3)/ioctl(16,
  TIOCGWINSZ via _isatty_compat) + animation deltas
  (rt_sigprocmask/signalfd4/nanosleep). M8 audit will record
  this as the v1.0 candidate set.
- **`--help` text** — M6 added three flags but `print_usage`'s
  Examples section still shows only the M1/M2 invocations.
  Refresh at M7's documentation pass with examples covering
  `--no-color`, `--force-color`, `--color=256`.
- **Animation under non-truecolor modes** — `_pretag_clusters` +
  `_render_frame` already exercise the per-mode escape table, so
  `anuenue -a --color=16 < poem.txt` works visibly. No tests
  cover the 16/256 + animation combination yet — animate-smoke
  only exercises `--color=24bit`. M7 may add structural smoke
  variants if a consumer surfaces a regression.

## Next

See [roadmap.md § M7](roadmap.md#m7--public-surface-freeze--guide-docs-v080).
