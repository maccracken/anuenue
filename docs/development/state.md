# anuenue — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.9.0** — *current.* cut 2026-05-22 (tenth release; sixth same-
day cut). **Quality slot — fuzz harness + animation smoke
breadth + structural cleanup.** No behavioural changes, no flag-
surface changes, no dep bumps. Three threads landed together:

1. **`fuzz/` directory populated.** Five harnesses targeting the
   surfaces the M8 audit identified — flag parser, UTF-8,
   `_pretag_clusters`, `_emit_phase_esc`, RGB quantizers — each
   using a Knuth-MMIX LCG for deterministic seed-driven
   exploration and returning `assert_summary()` so failed
   invariants set a non-zero exit code (the `assert` library
   prints-but-doesn't-abort; the exit-code propagation is what
   makes `cyrius fuzz` a real CI gate). Combined **1 354 580
   assertions** per run, zero failures. CI wired (`cyrius fuzz`
   step in `.github/workflows/ci.yml`).
2. **Animation smoke breadth.** `scripts/animate-smoke.sh` now
   covers `--color=256` and `--color=16` under `-a` in addition
   to the M4 truecolor path + M8 long-cluster regression. Each
   per-mode section asserts clean exit, full cursor lifecycle,
   and the per-mode SGR shape (CSI `38;5;Nm` for 256-color, CSI
   `9[1-7]m` for 16-color; explicit no-leak check that truecolor
   `38;2;…` doesn't appear under `--color=256`). Closes the
   carry-forward documented since v0.7.0.
3. **Structural cleanup.** The M0-anticipated `src/hsv.cyr` split
   finally lands — `ANUENUE_PHASE_MOD` + `hsv_rainbow` extracted
   into their own file. Triggered by the fuzz harness's
   `emit-phase-esc` target wanting a clean boundary; ADR 0002
   documents the broader "HSV inline, not abaco" reasoning.
   Plus a column-width pass on `src/main.cyr`'s flag-registration
   lines clearing the 5 pre-existing `cyrius lint` warnings
   flagged during the v0.8.0 closeout. DCE binary unchanged at
   **351 200 B** — the v0.9.0 work didn't touch the production
   surface, only moved code between files + added test/fuzz
   infrastructure.

Bug caught on the harness's own first run: my initial
`fuzz/flag-parser.fcyr` asserted `rc >= 0` but `lib/flags.cyr`
documents `flags_parse` as returning `-1` on error. Without the
exit-code-propagation change (`return assert_summary()`), the
failed assertion would have silently passed CI 12 times per run.
Fixed before the harness landed.

**0.8.0** — cut 2026-05-22 (ninth release; fifth same-day cut).
**M7 (docs) + M8 (security audit) folded into one cycle.** M7 shipped three ADRs (0001 pipe-purity / 0002 HSV-inline /
0003 grapheme-cluster cycling), the
[`docs/guides/integrating-anuenue.md`](../guides/integrating-anuenue.md)
downstream-consumer guide, eight runnable examples under
[`docs/examples/`](../examples/), and a `print_usage` Examples refresh
in `src/main.cyr` covering the M6 flags. M8 audit
([`docs/audit/2026-05-22-audit.md`](../audit/2026-05-22-audit.md))
turned up **one HIGH-severity finding**: `_render_frame` heap
overflow on long-cluster animation input (base char + ~32 500
combiners → 65 KB single cluster overflowing the 32 KB `line_buf`).
**Fixed in-cycle** via a mid-cluster flush guard in
`src/animate.cyr`'s byte-copy loop — flush + re-emit the same
phase escape when the reserve threshold trips mid-cluster. Visible
colour stays consistent; the buffer never overruns. Filter path
(`anuenue_filter`) was not affected because it writes one
codepoint per iteration. Regression coverage: new
`scripts/animate-smoke.sh` long-cluster section (16 000 combiners
after a base char; asserts clean exit + full byte preservation)
and a new tcyr group ("M8 audit — _pretag_clusters long-combiner
chain", 4 assertions; 241 → **245 total**). Zero HIGH+ findings
open at the end of the audit. Capability surface confirmed clean
(see [`docs/audit/2026-05-22-audit.md`](../audit/2026-05-22-audit.md)
§ Finding 2 for the v1.0 baseline). DCE binary 350 488 → **351 200 B
(+712)** — well under the 512 KB cap raised at v0.7.1.

**0.7.1** — cut 2026-05-22 (eighth release; fourth same-day cut).
**Sandhi closeout** for the M6 → darshana 0.5.3 loop. Pin bumped 0.5.2 → 0.5.3; three inline stand-ins
(`_isatty_compat`, `_fg_256_buf_compat`, `_sgr_buf_compat`)
deleted from `src/color.cyr`; call sites rewritten to call
darshana's `tty_isatty` / `tty_sgr_buf` / `tty_fg_256_buf`.
Signature-identical swap — all 6 goldens still byte-identical,
241/241 tests pass, ASCII no-LF perf actually improves ~1 ns/byte
(46.99 → 45.99). Binary 349 832 → **350 488 bytes (+656)** — the
swap pulled in `tty_itoa` and other transitive darshana helpers
the M6 stand-ins had bypassed. **DCE cap raised 350 KB → 512 KB**
in this same slot (the M5-set 350 KB number was a stretch by M6
and broke by 488 B after the swap; the M7-closeout cap-raise note
in this file gets landed here instead of drifting).

**0.7.0** — cut 2026-05-22 (seventh release; third same-day cut).
**M6 closed.** Color-mode negotiation:
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

**Quality slot (v0.9.0) — shipped.** Fuzz harness, animation
smoke breadth, structural cleanup. See the v0.9.0 entry under
Version above for the per-thread breakdown. No behavioural surface
delta vs v0.8.0; the production binary is byte-identical in size.
With both quality carry-forwards closed (fuzz + animation non-
truecolor), the only outstanding pre-v1.0 work is the consumer
soak window — both Dogfooded and Downstream gate need an external
consumer wiring anuenue in for a minor-cycle window.

**M7 (docs) + M8 (audit) — shipped at v0.8.0.** Doc half of the
v1.0 surface lock + the pre-v1.0 security pass, landed in one
cycle. ADRs 0001/0002/0003 record the rule that shapes everything
(pipe-purity), the not-pulling-abaco decision, and the practical-
subset grapheme classifier. `docs/guides/integrating-anuenue.md`
is the downstream-consumer manual; `docs/examples/` exercises every
flag at least once. The M8 audit
([`docs/audit/2026-05-22-audit.md`](../audit/2026-05-22-audit.md))
caught one HIGH-severity heap overflow in
`src/animate.cyr`'s `_render_frame` — adversarial long-cluster
input could overrun the 32 KB `line_buf` via the unbounded-cluster
byte copy. Fixed in-cycle with a mid-cluster flush guard; filter
path was unaffected. Zero HIGH+ findings open at the close of the
audit. Animation regression now covered at both unit-test
(`tests/anuenue.tcyr` M8 group) and integration (`scripts/animate-
smoke.sh` long-cluster section) levels.

**Sandhi closeout (v0.7.1) — shipped.** darshana 0.5.3 landed
(the third turn of the same crank that produced darshana 0.5.1
truecolor for M1 and 0.5.2 cursor-up for M4); anuenue's pin bumped
0.5.2 → 0.5.3 and the three M6-era stand-ins removed. Sandhi loop
closed. M6's behavioural surface is now backed by canonical
darshana helpers per the project rule (CLAUDE.md: *ANSI escape
generation belongs in darshana*).

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

Next slot is **v1.0.0 — GA tag** per
[roadmap.md § v1.0.0](roadmap.md#v100--ga). Surface frozen at
v0.8.0; capability baseline recorded by the M8 audit;
documentation set complete. The remaining v1.0 acceptance items
(*Dogfooded* + *Downstream gate*) need at least one external
consumer (likely `agnoshi` MOTD pipeline or `iam`) wiring anuenue
in for a minor-cycle soak window. Tagged on user signal per
[feedback_no_unprompted_version_bumps](https://github.com/MacCracken/agnosticos/blob/main/.claude/projects/-home-macro-Repos-agnosticos/memory/feedback_no_unprompted_version_bumps.md).

## Toolchain

- **Cyrius pin**: `6.0.1` (in `cyrius.cyml [package].cyrius`).
- Pin-lag spectrum: aligned with darshana 0.5.2 / sakshi 2.2.5 / agnostik 1.2.2 — all on 6.0.1 since scaffold. Re-evaluate at each minor cut; sandhi-bump if a dep ships a 6.0.x+ upgrade we want.

## Source

| File | Lines | Surface |
|------|-------|---------|
| `src/hsv.cyr` | ~95 | **NEW at v0.9.0** (the M0-anticipated split). Holds `ANUENUE_PHASE_MOD = 1530` + `hsv_rainbow(phase, out_rgb)` — the integer 6-sector S=V=1 HSV→RGB. Move was triggered by `fuzz/emit-phase-esc.fcyr` wanting a clean target boundary; ADR 0002 (HSV inline) documents the broader "don't pull abaco" decision. `main.cyr` / `filter.cyr` / `animate.cyr` / `tests/anuenue.tcyr` / `tests/anuenue.bcyr` all include this before `filter.cyr` since filter references `ANUENUE_PHASE_MOD`. |
| `src/color.cyr` | ~200 | **NEW at M6 (v0.7.0)**. Color mode enum (`ANUENUE_COLOR_MONO`/`_16`/`_256`/`_TRUE`); override-string parser + enum mapping (`_color_override_from_str` / `_color_mode_from_override`); RGB quantization (`_channel_to_6`, `_rgb_to_256` xterm cube; `_rgb_to_16` bright-palette); `anuenue_detect_color_mode(no_color, force_color, override)` reading getenv + darshana 0.5.3's `tty_isatty`; `anuenue_passthrough()` MONO bypass (read/write loop, no escapes). Sandhi closeout at v0.7.1 removed the three `_*_compat` stand-ins. |
| `src/filter.cyr` | ~480 | `ANUENUE_*` constants + **`ANUENUE_ESC_TABLE_ENTRY_SIZE`** (M5). `hsv_rainbow` + `ANUENUE_PHASE_MOD` extracted at v0.9.0 — now live in `src/hsv.cyr`. M3: `utf8_seq_len` / `utf8_decode` / `cp_is_extending` (M5: binary-searched LUT) / `cp_is_regional_indicator`. M5: `_phase_esc_init()` / `_emit_phase_esc()` / `_PHASE_ESC_TABLE` (1 530 × 32 B heap; idempotent). **M6 (v0.7.0)**: `_phase_esc_init` branches on `ANUENUE_COLOR_MODE` to populate per-mode escapes (TRUECOLOR via `tty_fg_rgb_buf`, 256 via `tty_fg_256_buf`, 16 via `tty_sgr_buf`). `anuenue_filter()` keeps the M5 hot path; ASCII short-circuit unchanged. **Unaffected by the M8 audit fix** — writes one codepoint per iteration with the reserve check between, so the long-cluster overrun doesn't reach the filter path. |
| `src/animate.cyr` | ~290 | M4 surface (animation: slurp + pretag + frame loop + signalfd). M5: ASCII short-circuit in `_pretag_clusters`; `_render_frame` routes through `_emit_phase_esc`; `_phase_esc_init` shared with filter. M6: animation benefits from per-mode escapes via the same path; MONO never reaches animation (main.cyr dispatches to passthrough first). **M8 (v0.8.0) fix**: `_render_frame`'s cluster-bytes copy loop got an inline mid-cluster flush guard — when the reserve threshold trips before all cluster bytes are written, flush + re-emit the same `phase` escape so the next bytes render under the same colour. Closes the long-cluster heap overflow surfaced by the audit. |
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

- **Size (0.9.0, DCE on)**: **351 200 bytes** (~343 KB). Delta vs
  0.8.0: **±0 bytes** — v0.9.0 added fuzz/ + smoke variants +
  the hsv.cyr split, but none of that work touched the
  production binary surface (DCE resolves the same reachable
  function set; moving `hsv_rainbow` between files doesn't
  change linkage). Cleanest possible quality-slot signal.
- **DCE elimination**: 1 240 unreachable fns, 219 668 bytes NOPed.
- **Cap discipline (v0.7.1+)**: **512 KB**. Current headroom ~161 KB.
- **Prior floors**: 0.8.0 = 351 200 B, 0.7.1 = 350 488 B, 0.7.0 = 349 832 B, 0.6.0 = 335 160 B, 0.5.0 = 334 120 B, 0.4.0 = 322 368 B, 0.3.0 = 317 216 B, 0.2.0 = 304 368 B.
- **Output path**: `build/anuenue`

## Tests

| File | Status |
|------|--------|
| `tests/anuenue.tcyr` | **245 assertions across 35 groups**. M1: smoke/HSV/geometry/constants (47). M2: flags (27). M3: utf8_seq_len/decode/cp_is_extending/cp_is_regional_indicator (30). M4: animate constants + _pretag_clusters + _count_lf_clusters + _input_ends_with_lf + -a/-d/-S flag parsing (42). M5: phase-cache idempotency, byte-identical round-trip, phase normalization, table layout (26). M6: mode enum + override parser + `_channel_to_6` bucket boundaries + `_rgb_to_256` canonical hues + `_rgb_to_16` bright-palette quantization + 256/16 escape framing + bounds rejection (69). **M8 (v0.8.0): "_pretag_clusters long-combiner chain" (4)** — A + 511 combiners → 1 cluster spanning 1023 bytes; locks the unbounded-cluster invariant the M8 audit fix relies on. End-to-end behaviour owned by golden + animate-smoke (+ M8 long-cluster section) + perf-bench. |
| `tests/anuenue.bcyr` | 2 micro-benchmarks: `hsv_rainbow` ≈8 ns/call, `tty_fg_rgb_buf` ≈45 ns/call. Pre-M5 the filter loop called both per cluster; M5+ uses `_emit_phase_esc` (~10 ns/call) instead. The micros still measure the table-build path. |
| `fuzz/*.fcyr` (v0.9.0+) | **Five harnesses populated.** `flag-parser.fcyr` (M2), `utf8.fcyr` (M3), `pretag-clusters.fcyr` (M4), `emit-phase-esc.fcyr` (M5), `rgb-quantizers.fcyr` (M6). Each uses a Knuth-MMIX LCG for deterministic seed-driven exploration; each returns `assert_summary()` so failed invariants set a non-zero exit code. Combined: **1 354 580 assertions** at v0.9.0 candidate, zero failures. `cyrius fuzz` is the gate; runs in CI. Previous `tests/anuenue.fcyr` stub deleted (wrong path; `cyrius fuzz` looks at `fuzz/*.fcyr`). |
| `tests/golden/*.out` | **Six fixtures**. M2/M3: `agnos-rainbow-s100` (238 B), `cjk-mixed-s0` (125 B), `combining-s0` (155 B), `zwj-flag-s0` (135 B). **M6: `agnos-rainbow-256-s100.out` (160 B), `agnos-rainbow-16-s100.out` (82 B)**. All six byte-identical across the M5/M6/M8 cuts — proves the mode-aware phase cache matches runtime exactly and that the M8 fix is local to the long-cluster path. Plus three MONO equivalence checks in golden-check.sh (`NO_COLOR=1 anuenue` / `--no-color` / `--color=none` all byte-identical to input). |
| `scripts/animate-smoke.sh` | M4 (v0.5.0). Animation structural guard. M6: invokes with `--color=24bit` so the TTY-detection in M6 doesn't drop the test into MONO. **M8 (v0.8.0) extension**: long-cluster section runs the historical attack (base + 16 000 combining acutes), asserts clean exit and full byte preservation (~976 000 combiner bytes over 61 frames) through the mid-cluster flushes. **v0.9.0 extensions**: `--color=256` + `--color=16` per-mode sections — each asserts clean exit, non-empty output, full cursor lifecycle, and the per-mode SGR shape (CSI 38;5;Nm for 256, CSI 9[1-7]m for 16; explicit no-leak check that truecolor 38;2;… doesn't appear under `--color=256`). |
| `scripts/perf-bench.sh` | M5 (v0.6.0). End-to-end ASCII + UTF-8 per-byte overhead. M6: invokes with `--color=24bit` for the same reason. The M5 ratchet. Latest run at v0.8.0: ASCII no-LF **45.94 ns/byte** (filter path untouched by M8). |

Assertion count history: M1 47 → M2 74 (+27) → M3 104 (+30) → M4 146 (+42) → M5 172 (+26) → M6 241 (+69) → M8 245 (+4).

## Dependencies

Direct (declared in `cyrius.cyml`):

| Dep | Tag | Role | Status |
|-----|-----|------|--------|
| `darshana` | 0.5.3 | ANSI color escape generation. Pin history: 0.5.1 (M1 truecolor `tty_fg_rgb_buf` / `tty_sgr_reset_buf`); 0.5.2 (M4 `tty_cursor_up(n)` / `tty_cursor_down(n)`); 0.5.3 (M6 sandhi closeout — `tty_isatty(fd)` / `tty_sgr_buf` / `tty_fg_256_buf`, replacing anuenue's M6-era stand-ins). | Live. Filter path uses `tty_fg_rgb_buf` + `tty_sgr_reset_buf`; animation path additionally uses `tty_cursor_up`, `tty_cursor_hide`, `tty_cursor_show`, `tty_sgr_reset`. |
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

- **M7 docs — closed at v0.8.0.** ADRs 0001/0002/0003,
  integration guide, eight examples, `print_usage` Examples
  refresh all shipped. Carry-forward note retired.
- **M8 audit — closed at v0.8.0.** Audit doc filed at
  [`docs/audit/2026-05-22-audit.md`](../audit/2026-05-22-audit.md);
  the HIGH finding (long-cluster heap overflow in `_render_frame`)
  is fixed; the LOW (large `-d` overflow → graceful exit) is
  documented as accepted graceful degradation; INFO findings
  (signalfd lifecycle, signal mask not restored, color override
  parser robustness) are recorded for future reference. Capability
  surface confirmed clean and recorded as the v1.0 baseline.
  Carry-forward note retired.
- **Fuzz harness — closed at v0.9.0.** Five harnesses live in
  `fuzz/`. Combined 1 354 580 assertions across deterministic
  seed sweeps; CI-gated via `cyrius fuzz`. Carry-forward retired.
- **Animation under non-truecolor modes — closed at v0.9.0.**
  `scripts/animate-smoke.sh` now covers `--color=256` and
  `--color=16` under `-a` with full cursor-lifecycle + SGR-shape
  assertions. Carry-forward retired.
- **Dogfooded + Downstream gate (v1.0 acceptance)** — the
  remaining two v1.0 criteria need at least one external
  consumer wiring anuenue in for a minor-cycle soak window.
  Anticipated consumers: `agnoshi` MOTD pipeline composition or
  `iam`'s default login splash chain. Tracking until then.

## Next

See [roadmap.md § v1.0.0](roadmap.md#v100--ga).
