# anuenue — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.5.0** — *current.* cut 2026-05-22 (fifth release, first after
the four same-day cuts that landed 0.1.0–0.4.0). **M4 closed.**
Animation mode: `-a` / `-d <secs>` / `-S <speed>`. Buffers stdin
once (64 KB ceiling), pre-tags grapheme clusters with the M3 state
machine, repaints at ~60 fps with phase shifted per frame.
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

**M4 (Animation Mode) — shipped at v0.5.0.** Three new flags
(`-a` / `-d` / `-S`) dispatch to a new `anuenue_animate` driver
that lives in `src/animate.cyr`. The driver buffers stdin (64 KB
input ceiling, 8 192-cluster index ceiling), pre-tags grapheme
clusters once, then loops a render-sleep-cursor_up sequence at
~60 fps (16 ms frame interval). Phase advances by `-S` units per
frame (default 1) to scroll the rainbow through the buffered
block. SIGINT / SIGTERM / SIGHUP cleanup goes through a non-
blocking signalfd probed between frame sleeps — the signals are
masked at the process level via `sys_sigprocmask` so they queue
on the fd instead of killing the process mid-render.

Pipe-purity deviation (carry-forward to ADR 0001): animation mode
buffers up to 64 KB of stdin, deliberately deviating from the
M1/M2/M3 "no buffering beyond a line" rule. Bounded by the input
ceiling and the cluster-table ceiling; both heap-allocated and
documented at the alloc site.

darshana 0.5.2 sandhi-unlock: the M4 dep gate needed relative
cursor-up. `tty_cursor_up(n)` + `tty_cursor_down(n)` added to
darshana 0.5.2; anuenue pin advances. Pure additions on the
darshana surface — other consumers (cyim 1.7.1, chakshu 0.6.1,
bannermanor) unaffected.

Next slot is **M5 — Performance Pass (v0.6.0)** per
[roadmap.md § M5](roadmap.md#m5--performance-pass-v060): ASCII
short-circuit + flattened `cp_is_extending` LUT + phase-cached
escape buffer. Target: recover the ASCII hot-path overhead M3
introduced (53 → 86 ns/byte regression) without giving up cluster
correctness. No dep gate; pure internal optimisation.

## Toolchain

- **Cyrius pin**: `6.0.1` (in `cyrius.cyml [package].cyrius`).
- Pin-lag spectrum: aligned with darshana 0.5.2 / sakshi 2.2.5 / agnostik 1.2.2 — all on 6.0.1 since scaffold. Re-evaluate at each minor cut; sandhi-bump if a dep ships a 6.0.x+ upgrade we want.

## Source

| File | Lines | Surface |
|------|-------|---------|
| `src/filter.cyr` | ~440 | `ANUENUE_*` constants (phase mod/step/start, line-buf / read-chunk / flush-reserve sizing — flush-reserve bumped 22→32 at M3 for 4-byte codepoints); `hsv_rainbow(phase, out_rgb)` — integer 6-sector HSV. **M3 (v0.4.0)**: `utf8_seq_len(buf, i, n)` returns 1/2/3/4 valid, 0 truncated, 1 invalid; `utf8_decode(buf, i, seqlen)` codepoint assembly; `cp_is_extending(cp)` practical-subset combining-mark classifier; `cp_is_regional_indicator(cp)` flag pair. `anuenue_filter()` cluster-aware loop with three latches (`saw_any`, `prev_was_zwj`, `prev_unpaired_ri`) and chunk-boundary carry. M2 made `ANUENUE_PHASE_STEP` and `ANUENUE_PHASE_START` flag-overridable. |
| `src/animate.cyr` | ~270 | **NEW at M4 (v0.5.0)**. `ANUENUE_ANIMATE_INPUT_MAX` / `_CLUSTER_MAX` / `_FRAME_MS` / `_DEFAULT_DURATION_S` / `_DEFAULT_SPEED` / `_SFD_NONBLOCK` constants. `_animate_slurp_stdin(buf, cap)`, `_pretag_clusters(buf, n, ctab, max)`, `_count_lf_clusters`, `_input_ends_with_lf`, `_render_frame`, `_open_exit_signalfd`, `_signal_pending`, `anuenue_animate(duration_secs, speed)`. Re-uses filter.cyr's UTF-8 primitives + HSV + cluster classification; depends on chrono.sleep_ms + chrono.clock_now_ns and darshana 0.5.2's `tty_cursor_up`. |
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

- **Size (0.5.0, DCE on)**: **334 120 bytes** (~326 KB).
  Delta vs 0.4.0: **+11 752 bytes** for the M4 animation surface
  (animate.cyr ~270 lines + chrono.sleep_ms + chrono.clock_now_ns
  + the signalfd / sigprocmask path). M5 (perf pass) will set a
  production budget against this floor.
- **DCE elimination**: 1 251 unreachable fns, 220 882 bytes NOPed.
- **Prior floors**: 0.4.0 = 322 368 B, 0.3.0 = 317 216 B, 0.2.0 = 304 368 B.
- **Output path**: `build/anuenue`

## Tests

| File | Status |
|------|--------|
| `tests/anuenue.tcyr` | **146 assertions across 27 groups**. M1: smoke/HSV/geometry/constants (47). M2: long/short bool, int extraction, attached long-form, additive seed+offset, error variants, version literal (27). M3: utf8_seq_len 1/2/3/4-byte detection, invalid + truncated handling, utf8_decode canonical codepoints, cp_is_extending across ranges, cp_is_regional_indicator bounds (30). **M4: animate constants sanity, _pretag_clusters ASCII / combining / CJK / truncated / overflow cap, _count_lf_clusters, _input_ends_with_lf, -a/-d/-S flag parsing across short / long / attached-long forms (42)**. Cyrius can't trivially redirect fd 0/1 in unit scope, so the end-to-end byte-stream is owned by the golden harness + animate-smoke. |
| `tests/anuenue.bcyr` | **2 micro-benchmarks** (1M iter each): `hsv_rainbow` ≈8 ns/call, `tty_fg_rgb_buf` ≈45 ns/call. Captured against the M1 baseline in `docs/benchmarks.md`. |
| `tests/anuenue.fcyr` | fuzz stub — first harness still pending. The M3 UTF-8 surface (`utf8_seq_len` over random byte tokens) and the M4 `_pretag_clusters` cluster state machine are both natural targets. |
| `tests/golden/*.out` | **Four fixtures**: `agnos-rainbow-s100` (M2 ASCII baseline, 238 B), `cjk-mixed-s0` (M3 CJK+ASCII, 125 B), `combining-s0` (M3 é + rainbow, 155 B), `zwj-flag-s0` (M3 ZWJ family + flag, 135 B). Asserted by `scripts/golden-check.sh` and CI's **Golden output** step. M4 adds no goldens (animation is non-deterministic by design); structural contract asserted by `scripts/animate-smoke.sh`. |
| `scripts/animate-smoke.sh` | **NEW at M4 (v0.5.0)**. Structural guard for animation mode: exit 0 on duration-elapsed + on SIGINT, cursor-hide / cursor-show framing, cursor-up emitted between frames. Wired into CI as **Animation smoke (M4)**. |

Assertion count history: M1 47 → M2 74 (+27) → M3 104 (+30) → M4 146 (+42).

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
  animation mode buffers up to 64 KB of stdin before rendering
  (bounded, documented at the alloc site, only on `-a`). The ADR
  draft now needs to record both the rule AND its one exception.
- **`tests/anuenue.fcyr`** — fuzz harness stub still empty. Three
  natural targets now: the M2 flag parser (random argv tokens →
  `flags_parse` never crashes), the M3 UTF-8 surface
  (`utf8_seq_len` over arbitrary byte streams), and **the M4
  `_pretag_clusters` cluster state machine** (latches under
  random byte streams — never crash, never over-read, always
  emit a sentinel). Defer until M5 or whenever a parse / decode /
  cluster bug is discovered in the wild.
- **DCE binary size after M4** — captured at 0.5.0 cut: 334 120
  bytes (+11 752 B vs 0.4.0; +16 904 B vs 0.3.0). Recapture at
  every minor cut. M5 perf pass aims to recover ASCII-path
  overhead; if the work touches dead branches it may shrink the
  binary too.
- **darshana 0.5.2 surface use** — `tty_cursor_down(n)` shipped
  alongside `tty_cursor_up(n)` for symmetry but anuenue currently
  uses only `_up`. Documented here so a future audit doesn't flag
  the unused symbol as a darshana surface mistake; cyim or
  chakshu may take `_down` as second consumer.
- **Capability surface delta on `-a`** — adds rt_sigprocmask(14)
  + signalfd4(289) + nanosleep(35) to the syscalls the filter
  path uses. M8 security audit will record these as the v1.0-
  frozen capability set; M4 added them, M5/M6/M7 should not.

## Next

See [roadmap.md § M5](roadmap.md#m5--performance-pass-v060).
