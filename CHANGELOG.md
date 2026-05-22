# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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

- VERSION stays at `0.1.0` — M1 is the **open cycle** of `0.2.0`
  but the user drives the bump-on-open per
  `feedback_no_unprompted_version_bumps`. The roadmap's
  M1-acceptance work lives in `[Unreleased]` until the bump
  instruction lands.

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
