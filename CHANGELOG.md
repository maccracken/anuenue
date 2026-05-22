# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.6.0] — 2026-05-22 — M5: Performance Pass

The hot-path-recovery cut. Three layered optimisations against the
M3 ASCII regression: an ASCII short-circuit that skips the UTF-8
decoder + cluster classifier on `b < 0x80`, a binary-searched range
LUT replacing the 21-condition `cp_is_extending` chain, and a
pre-baked 1 530-entry escape table indexed by `phase % MOD` that
collapses `hsv_rainbow + tty_fg_rgb_buf` into a single memcpy on
the hot path. Result on the canonical 1.4 MB base64-ASCII corpus:
**91.6 → 47.0 ns/byte (−48.7%)** — beats the v0.3.0 53 ns/byte
floor that M3 had regressed. All four M3 goldens remain byte-
identical; 26 new tcyr assertions lock the phase-cached escape
table's bytes to the runtime path. Binary stays under the 350 KB
DCE cap.

### Added

- **M5 — Performance Pass.** Three optimisations layered into the
  filter loop and the animation render loop:
  1. **ASCII short-circuit** — `if (b < 0x80)` branch in
     `anuenue_filter`'s inner walk and in `_pretag_clusters`'s
     classify pass. Skips `utf8_seq_len` + `utf8_decode` +
     `cp_is_extending` + `cp_is_regional_indicator` on every ASCII
     byte (which by construction can never be combining, RI, or
     multi-byte). The one edge case — ZWJ followed by ASCII —
     stays correct via the `prev_was_zwj` latch the fast path
     honours. Largest single win on MOTD-shaped traffic.
  2. **Binary-searched `cp_is_extending` LUT** — replaces the
     v0.4.0 21-range linear chain with a sorted `[lo, hi]` pair
     table and `O(log N)` lookup. Cheap reject for the common
     cases (`cp < 0x0300` or `cp > 0xE01EF`) skips the search
     entirely — covers CJK / Latin-1 / most-of-Unicode. Helps
     UTF-8-heavy non-Latin corpora; perf-neutral on ASCII
     (already short-circuited).
  3. **Phase-cached escape buffer** — 1 530-entry table indexed
     by `phase % ANUENUE_PHASE_MOD` holding pre-formatted
     `\x1b[38;2;R;G;Bm` escapes. Replaces `hsv_rainbow + 3×
     _ansi_emit_u8` (~53 ns/call) with one length-prefixed
     memcpy (~10 ns/call). 32-byte stride per entry (8-byte
     length + 19-byte payload + pad) — matches a cache-line
     fill. Heap-allocated at first-use (~80 μs once at startup),
     so the DCE binary doesn't grow.
- **`scripts/perf-bench.sh`** — scriptizes the end-to-end ASCII
  per-byte measurement docs/benchmarks.md kept describing
  manually. Generates a deterministic ASCII corpus + a UTF-8
  corpus, runs `cat fixture > /dev/null` and `anuenue < fixture
  > /dev/null` N times each, reports the median ns/byte
  overhead. Used to capture the M5 baseline AND prove each
  optimisation's win before claiming it.
- **26 new tcyr assertions in `tests/anuenue.tcyr`** under
  `M5 perf — phase-cached escape table`: `_phase_esc_init`
  idempotency, per-entry byte-identical round-trip against
  `hsv_rainbow + tty_fg_rgb_buf` (8 canonical phases including
  the wraparound corner), phase normalization (negative and
  `>MOD` phases hit the same entries as their canonical
  representatives), and table-layout invariants (32-byte
  stride, 13..19-byte entry length envelope).
- **`docs/benchmarks.md` § v0.6.0 — M5**: the three-point trend
  the roadmap acceptance called for (v0.3.0 → v0.4.0 → v0.6.0)
  plus the new perf-bench.sh-produced figures.

### Performance

End-to-end ASCII per-byte overhead, 1.4 MB base64-of-/dev/urandom
corpus, median of 7 runs:

| Path             | v0.5.0  | v0.6.0  | Δ       |
|------------------|---------|---------|---------|
| ascii (no LF)    | 91.6 ns | 47.0 ns | −48.7%  |
| ascii (w/ LFs)   | 95.0 ns | 51.0 ns | −46.3%  |
| utf8 mixed       | 66.3 ns | 43.0 ns | −35.1%  |

v0.6.0's ASCII no-LF figure (47 ns/byte) is **faster than the
v0.3.0 baseline (53 ns/byte)** — the M3 cluster-classification
regression is more than recovered. UTF-8 mixed is faster than
ASCII at v0.3.0 ever was; M3's per-cluster work amortises over
multi-byte payloads and the escape pre-computation skips the
expensive digit-encoding on every cluster.

### Changed

- `src/filter.cyr` — `cp_is_extending` rewritten as binary search
  over `_CP_EXT_TABLE`. New `_phase_esc_init` / `_emit_phase_esc`
  helpers + `_PHASE_ESC_TABLE` module-level pointer. The filter
  loop's hot path replaces the `hsv_rainbow + tty_fg_rgb_buf`
  pair (+ stack-allocated `var rgb[24]`) with a single
  `_emit_phase_esc` call.
- `src/animate.cyr` — same three changes mirrored: ASCII short-
  circuit in `_pretag_clusters`; `_render_frame` routes through
  `_emit_phase_esc`; per-frame stack-allocated `rgb[24]` dropped.
  `anuenue_animate` calls `_phase_esc_init()` at startup like
  the filter does.
- `src/main.cyr` — no behavioural change. `anuenue_filter` and
  `anuenue_animate` now both initialise the phase-cached escape
  table at entry; the cost is paid once per invocation and shared
  across both paths.

### Binary

DCE size: 334 120 → **335 160 bytes** (+1 040 B for the M5 helper
fns + LUT init code; the 48 KB phase-cache table itself is
runtime heap and doesn't bloat the binary). Well under the M5
acceptance cap of 350 KB DCE.

## [0.5.0] — 2026-05-22 — M4: Animation Mode

The lolcat-`-a` cut. Three new flags (`-a` / `-d` / `-S`) sit between
the M2 argv parser and a new `anuenue_animate` driver that buffers
stdin once, pre-tags grapheme clusters with the M3 state machine,
and repaints the buffered block at ~60 fps with the rainbow's phase
shifted per frame. Non-animation invocations are unchanged — the
v0.3.0 `-s 100` golden remains byte-identical, all four M3 fixtures
remain green. SIGINT / SIGTERM / SIGHUP cleanup is wired through a
non-blocking signalfd probe between frames: a Ctrl-C during
animation restores the cursor, resets SGR, and exits 0 instead of
killing the process mid-render.

### Added

- **M4 — Animation Mode.** `-a` / `--animate` enables animation;
  `-d <secs>` / `--duration` sets the run length in seconds (default
  5; `0` means "until SIGINT", mirroring lolcat); `-S <step>` /
  `--speed` sets the per-frame phase advance (default 1). Frame
  interval is hardcoded at 16 ms (~60 fps) — the M5 perf pass may
  expose this as a flag if a consumer asks.
- **`src/animate.cyr`** — new module, ~270 lines. Surface:
  - `_animate_slurp_stdin(buf, cap)` — reads stdin in a loop until
    EOF or capacity (64 KB ceiling); graceful truncation past the
    cap (the tail bytes simply don't animate).
  - `_pretag_clusters(buf, n, ctab, max)` — runs the M3 cluster
    state machine once over the buffered input, recording each
    cluster's start offset into `ctab` (one i64 per cluster + a
    sentinel slot holding the total byte count). 8 192-cluster
    cap; ~64 KB for the index. Cluster length per render is
    derived as `ctab[i+1] - ctab[i]` — no per-frame UTF-8 reparse.
  - `_count_lf_clusters` / `_input_ends_with_lf` — helper math
    for the cursor re-anchor distance and the trailing-CR
    decision.
  - `_render_frame(buf, ctab, n_clusters, phase_base, line_buf,
    ends_lf)` — walks the cluster table emitting fg-escape +
    cluster bytes into the same 32 KB line buffer the filter
    uses; flushes on LF / near-full / EOF. Tail emits SGR reset
    and a CR when input lacks a trailing LF, so the cursor lands
    at column 1 for the next frame's `tty_cursor_up` re-anchor.
  - `_open_exit_signalfd` / `_signal_pending` — non-blocking
    signalfd (SFD_NONBLOCK = O_NONBLOCK = 2048) masking
    HUP/INT/TERM. The frame loop probes the fd between sleep
    intervals and breaks cleanly when any exit signal arrives.
    Bypasses `darshana::tty_open_signalfd` (which creates a
    blocking fd for epoll-driven consumers) — the helper is the
    right shape for cyim/chakshu, wrong for anuenue's
    sleep_ms-driven cadence.
  - `anuenue_animate(duration_secs, speed)` — orchestrator.
    Hides the cursor, runs the frame loop, restores cursor +
    SGR on every exit path (clean / signal / read error / OOM).
- **42 new assertions across 9 groups** in `tests/anuenue.tcyr`:
  M4 constants sanity (defaults positive, SFD_NONBLOCK = 2048);
  `_pretag_clusters` over ASCII / combining diacritic / CJK /
  truncated UTF-8 / overflow cap; `_count_lf_clusters`;
  `_input_ends_with_lf`; M4 flag parsing (`-a` alone /
  `-a -d N -S M` / `--animate --duration=0`).
- **`scripts/animate-smoke.sh`** — structural guard for animation
  mode. Animation can't have a byte-identical golden (frame count
  varies with host load), so this script asserts the contract
  instead: exit 0 on duration-elapsed AND on SIGINT, cursor-hide
  + cursor-show framing present, at least one cursor-up emitted.
  Wired into CI as the **Animation smoke (M4)** step between
  Golden output and Version consistency.
- **`stdlib += chrono`** in `cyrius.cyml [deps].stdlib` — frame
  timing (`sleep_ms`) and deadline math (`clock_now_ns`).
  Standard AGNOS-userland chrono usage; same pin already used by
  every consumer needing wall-clock or monotonic time.

### Changed

- **darshana pin bumped** 0.5.1 → 0.5.2 — the v0.5.2 cut adds
  `tty_cursor_up(n)` (CSI `<n>A`) and `tty_cursor_down(n)` (CSI
  `<n>B`) to round out the cursor surface. Sandhi-unlock pattern,
  second turn of the same crank that produced 0.5.1 — anuenue is
  the consumer asking, darshana exposed the relative-cursor
  primitives, anuenue's pin advances to consume them. Pure
  additions on the darshana surface; M1/M2/M3 paths use only the
  previously-available helpers.

### Capability surface

- **Animation mode adds** three syscalls to anuenue's surface:
  `rt_sigprocmask(14)` (block exit signals), `signalfd4(289)`
  (open the non-blocking probe fd), `nanosleep(35)` (frame
  interval via chrono.sleep_ms). The filter path (no `-a`) keeps
  the M2 surface intact: `read(0)` + `write(1)` + `brk(12)` +
  `exit(60)` + `open(2)` / `close(3)` (one-shot, for
  `/proc/self/cmdline` at argv parsing). The M8 security audit
  will record these as the v1.0-frozen capability set.

### Pipe-purity deviation

Animation mode buffers up to 64 KB of stdin before rendering. This
deviates from the "no buffering beyond a line" rule the filter
loop enforces — animation needs a known-length block to repaint.
The deviation is bounded (input-buffer ceiling, cluster-table
ceiling) and limited to the `-a` invocation. ADR 0001
(pipe-purity, planned at M7) will record the rule and its single
animation-mode exception explicitly.

## [0.4.0] — 2026-05-21 — M3: UTF-8 Grapheme Awareness

The Unicode-correct-by-default cut. Filter cycles by grapheme
*cluster*, not byte: multi-byte CJK / combining marks / emoji-ZWJ
sequences / regional-indicator flag pairs all advance phase once
per visible glyph, not once per UTF-8 byte. ASCII fast-path stays
byte-identical (v0.3.0's `-s 100` golden remains green). Practical-
subset classifier — ships ~18 combining-mark ranges + ZWJ + VS + RI;
Hangul L/V/T and some Brahmic spacing marks misclassify as advancing
(errs on "more rainbow, not less"). ADR 0003 (M7) will record the
trade vs full UAX #29. Invalid UTF-8 → graceful per-byte degradation
(never panics). Chunk-boundary carry handles 4 096-byte read splits.

### Added

- **M3 — UTF-8 Grapheme Awareness.** Filter cycles by Unicode
  *cluster*, not byte. Multi-byte UTF-8 codepoints get one phase
  advance instead of N (`日` doesn't render as three rainbow
  segments); combining marks fold into their base codepoint (`é`
  = e + ◌́ at one phase); emoji ZWJ sequences render as a single
  cluster (👨‍👩‍👧 = one phase advance); regional-indicator pairs
  collapse to one cluster (🇺🇸 = one phase advance). The M1 ASCII
  path stays byte-identical — the v0.3.0 -s 100 golden fixture
  remains green.
- **UTF-8 primitives in `src/filter.cyr`**:
  - `utf8_seq_len(buf, i, n)` — 1/2/3/4-byte sequence detection.
    Returns 1 on invalid leading byte or invalid continuation
    (graceful degradation — the byte gets cycled as a singleton);
    returns 0 when a multi-byte sequence is truncated at the
    chunk boundary (carry signal).
  - `utf8_decode(buf, i, seqlen)` — assembles the codepoint from
    the validated sequence bytes.
  - `cp_is_extending(cp)` — practical-subset combining-mark
    classifier: Latin/Cyrillic/Hebrew/Arabic combiners + ZWJ + VS
    + half marks + math-zone combiners + variation selector
    supplement. Documents the trade vs full UAX #29 inline.
  - `cp_is_regional_indicator(cp)` — flag-pair recognition.
- **Chunk-boundary carry**. A multi-byte sequence that straddles
  the 4 096-byte read boundary is split correctly: the partial
  bytes carry over to the head of `read_buf`, and the next
  `read(2)` appends after them. EOF with carry → graceful
  per-byte cycling (the truncated sequence will never complete).
- **Cluster state machine** in `anuenue_filter`. Three latches:
  `saw_any` (suppress pre-advance on the very first cluster),
  `prev_was_zwj` (the codepoint after ZWJ joins the cluster —
  emoji-ZWJ-sequence rule), `prev_unpaired_ri` (pair regional
  indicators into flag emoji).
- **30 new assertions across 5 new groups** in
  `tests/anuenue.tcyr`: `utf8_seq_len` 1/2/3/4-byte detection,
  invalid + truncated handling, `utf8_decode` canonical codepoints
  (é / 日 / 🌈), `cp_is_extending` coverage (combining marks,
  ZWJ, VS, half marks, math zone, VS supplement, non-extending
  controls), `cp_is_regional_indicator` range bounds.
- **Three new golden fixtures** in `tests/golden/`:
  - `cjk-mixed-s0.out` — `日本AGNOS` at seed 0 (CJK + ASCII)
  - `combining-s0.out` — `é + rainbow` (combining diacritic)
  - `zwj-flag-s0.out` — `👨‍👩‍👧🇺🇸` (ZWJ + RI cluster stress)
  `scripts/golden-check.sh` refactored into a `check_golden`
  helper; all four fixtures asserted by CI's Golden output step.

### Changed

- `ANUENUE_FLUSH_RESERVE` bumped from 22 → 32 to fit a 4-byte
  codepoint's worst-case render envelope (19-byte fg escape + 4
  payload bytes + 4-byte reset). M1/M2's 22 was sized for 1-byte
  payloads only.
- `anuenue_filter` walks UTF-8 sequences instead of bytes; LF
  detection is a fast-path leading-byte check before
  `utf8_seq_len` runs. ASCII branch is preserved (single-byte
  cluster, advance phase).

### Performance

- **ASCII path slower** — ~86 ns/byte vs v0.3.0's 53 ns/byte
  (~62% regression on the M2 baseline) due to per-codepoint
  cluster classification. UTF-8 corpus runs comparable per-byte
  (~77 ns) since multi-byte codepoints amortise the per-cluster
  work over 2–4 payload bytes.
- **DCE binary** — 322 368 bytes (+5 152 vs v0.3.0).
- Both metrics tracked in `docs/benchmarks.md`. M5 (perf pass,
  v0.6.0) targets recovering the ASCII hot-path cost.

### Evaluated and rejected

- **vyakarana dep** — the roadmap M3 entry listed vyakarana as a
  candidate for grapheme-cluster boundary detection. Investigation
  showed vyakarana is a **source-code tokenizer** (token-kind spans
  for syntax highlighting via CYML grammars), not a Unicode
  database. Wrong domain. anuenue ships an inline practical-subset
  classifier instead; ADR 0003 (M7) will record the trade.

## [0.3.0] — 2026-05-21 — M2: Flag Surface

lolcat-equivalent CLI lands. Five flags (`-h`/`-V`/`-p`/`-s`/`-F`)
sit between argv and the M1 filter loop; the loop itself is
byte-identical to v0.2.0. Determinism is now a CI-asserted property
(committed 238-byte golden fixture), and the `anuenue X.Y.Z` literal
is auto-generated from `VERSION` so the cyim-1.2.2-style drift can't
happen here.

### Added

- **M2 — Flag Surface.** lolcat-equivalent CLI with five flags:
  `-h` / `--help`, `-V` / `--version`, `-p` / `--freq <N>` (phase
  step per character; default 7), `-s` / `--seed <N>` (starting
  hue phase — the deterministic-output hook), `-F` / `--offset <N>`
  (additive phase offset; Ruby-lolcat compat). `-s` and `-F` are
  additive (PHASE_START = seed + offset) so they compose without
  precedence surprises. Parse errors surface a specific message
  (unknown flag / missing value / bad int / bundled-short rejection)
  followed by usage, exit 2.
- **Stdlib expansion** — `args` and `flags` added to
  `cyrius.cyml [deps].stdlib`. The flag parser is the AGNOS-
  canonical `lib/flags.cyr` (used by every toolchain binary and
  consumer); the inline-vs-stdlib roadmap note was tightened —
  stdlib doesn't count as "adding a flag-parsing lib." Capability
  surface gained `open(2)` + `close(3)` at startup for
  `/proc/self/cmdline` via `args_init()`; the filter loop itself
  remains read(0) / write(1) / brk(12) / exit(60) only.
- **Version-bump pipeline** (`scripts/version-bump.sh` + auto-
  generated `src/version_str.cyr`) — cyim's drift-prevention
  pattern, adapted. The `anuenue X.Y.Z` literal is regenerated on
  every bump; CI's new **Version consistency** step asserts the
  literal matches `VERSION` (and CHANGELOG has a section for the
  current version, and `cyrius.cyml` still pulls via
  `${file:VERSION}`). Drives `print_version()` in
  `src/main.cyr` — never hand-edit `src/version_str.cyr`.
- **Determinism golden** — `tests/golden/agnos-rainbow-s100.out`
  + `scripts/golden-check.sh`. Asserts `printf "AGNOS rainbow" |
  ./build/anuenue -s 100` produces a byte-identical 238-byte
  output every time. Wired into CI as the **Golden output**
  step. Catches regressions the unit suite can't see (HSV
  geometry, escape framing, line-flush ordering).
- **27 new assertions across 7 new groups** in
  `tests/anuenue.tcyr`: long-form bool dispatch (`--help`); short-
  form bool dispatch (`-V`); int extraction over short forms
  (`-p 13 -s 42 -F 100`); attached long-form value (`--freq=99`);
  additive seed+offset semantics (510+510 lands at phase 1020 →
  blue); error-variant dispatch (UNKNOWN, MISSING_VALUE, BAD_INT);
  `_VERSION_STR_ANUENUE` literal-shape sanity (prefix + LF
  terminator + length match).

### Changed

- `src/filter.cyr` — `ANUENUE_PHASE_STEP` and the new
  `ANUENUE_PHASE_START` are mutable module-level vars; `main.cyr`
  overwrites them from flags before `anuenue_filter()` runs.
  Default behavior unchanged from v0.2.0.
- `.github/workflows/ci.yml` — three new steps: **Golden output**,
  **Version consistency**.

## [0.2.0] — 2026-05-21 — M1: Minimum Viable Filter

The pipe-purity proof. stdin → stdout, per-byte 24-bit-truecolor
rainbow tint, capability surface = read(0) + write(1) + brk(12) +
exit(60). Drove the darshana 0.5.1 truecolor unlock as the sandhi
consumer for the new `tty_fg_rgb_buf` + `tty_sgr_reset_buf`
helpers.

### Added

- **M1 — Minimum Viable Filter.** stdin → stdout per-byte rainbow
  tint via 24-bit ANSI fg, emitted through darshana 0.5.1's new
  `tty_fg_rgb_buf` / `tty_sgr_reset_buf` primitives. Pipe-pure:
  capability surface is `read(0)` + `write(1)` + `brk(12)` +
  `exit(60)` — no `open`, `connect`, `fork`, `exec`, `signal`,
  `ioctl`. Implementation lives in `src/filter.cyr`:
  - **`hsv_rainbow(phase, out_rgb)`** — integer-only HSV → RGB for
    full-saturation full-value rainbow. 6-sector geometry over a
    1530-unit phase space (6 × 255 sub-steps). Canonical pure hues
    fall on exact integer (R,G,B) at sector boundaries with no
    rounding; sub-sector linear ramps go 0→255 / 255→0 deterministically.
  - **`anuenue_filter()`** — reads stdin in 4096-byte chunks; emits
    each byte prefixed by its phase-derived fg escape into a 32KB
    line buffer; flushes on LF (with `\x1b[0m` reset so the terminal
    returns clean for the shell prompt) or when the next worst-case
    escape + payload + reset wouldn't fit (force-flush). 22-byte
    reserve guards against scribbling past the buffer.
- **Module split** (`src/main.cyr` + `src/filter.cyr`). main.cyr is
  the entrypoint shell (alloc_init + `anuenue_filter()` call +
  `syscall(SYS_EXIT, ...)`); filter.cyr is the testable library
  surface — the test suite includes it without triggering the
  top-level `main()` call. Closes the state.md "module split
  planned at M1 — defer until the code earns it" note.
- **47 assertions across 6 groups** in `tests/anuenue.tcyr`:
  smoke; `hsv_rainbow` canonical hues (red / yellow / green / cyan
  / blue / magenta + wraparound at phase=1530); sector-ramp mid-
  points (sectors 0 / 1 / 3 / 5); phase normalization (large + negative
  inputs); filter-geometry flush-reserve sizing (round-trips
  `tty_fg_rgb_buf`'s max-escape envelope); module-constant sanity
  (no per-byte phase wrap, flush amortizes ≥100 chars).
- **`tests/anuenue.bcyr`** — first benchmarks. `hsv_rainbow` 8ns
  avg / `tty_fg_rgb_buf` 45ns avg over 1M iterations each.
  Captured in **`docs/benchmarks.md`** along with the end-to-end
  baseline (≈53 ns/byte over cat; 17.4× output expansion on
  base64 ASCII).
- **darshana pin bumped** `0.5.0 → 0.5.1` — the new pin ships the
  24-bit truecolor SGR helpers anuenue's M1 drove into existence.
  Sandhi-unlock pattern: anuenue is the consumer that asked,
  darshana exposed `tty_fg_rgb` / `tty_bg_rgb` + buf-targeting
  variants, anuenue's pin advances to consume them.

### Notes

- darshana pin bumped 0.5.0 → 0.5.1 as the sandhi-unlock pattern's
  consumer half: anuenue asked for truecolor, darshana shipped the
  surface, anuenue's pin advanced to consume it. Both repos cut
  same-day (2026-05-21).
- DCE binary captured at the cut — see `docs/development/state.md`
  binary row.
- Module split landed (`src/filter.cyr` + `src/main.cyr`); the
  predicted third file `src/hsv.cyr` didn't earn a split at M1 and
  may be revisited at M3 (UTF-8 grapheme awareness).

## [0.1.0] — 2026-05-21

### Added
- Initial project scaffold via `cyrius init anuenue` (cyrius 6.0.1).
- AGNOS first-party dep wiring: `darshana` 0.5.0 (ANSI substrate), `sakshi` 2.2.5 (errors/tracing per standards), `agnostik` 1.2.2 (shared types).
- CLAUDE.md filled from [example_claude.md](https://github.com/MacCracken/agnosticos/blob/main/docs/development/planning/example_claude.md) — durable rules, anuenue-specific principles (pipe-purity, capability-boundedness, HSV phase model, UTF-8 grapheme awareness).
- `docs/development/roadmap.md` — M0 → v1.0 plan across 9 milestones with dep gates, acceptance criteria, and explicit out-of-scope list.
- `docs/development/state.md` — initial state snapshot.
- README — anuenue-specific identity, etymology (Hawaiian ānuenue), positioning as founder of the pipe-decorator family.
- Registry entry in agnosticos `docs/development/planning/shared-crates.md` § Pipe-decorator family (new sub-section).

### Notes
- No filter logic yet — `src/main.cyr` is the `cyrius init` hello-world. M1 (v0.2.0) is the pipe-purity proof: stdin → stdout, byte-level cycling, 24-bit ANSI via darshana.
