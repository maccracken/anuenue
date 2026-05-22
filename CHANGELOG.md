# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
