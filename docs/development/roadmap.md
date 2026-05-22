# anuenue — Roadmap

> Milestone plan through v1.0. State lives in [`state.md`](state.md);
> this file is the sequencing — what ships, in what order, against
> what dependency gates.

## What anuenue is

A Cyrius-native `lolcat` equivalent. Pure stdin → stdout pipe filter that tints each character (or grapheme cluster, post-M3) along an HSV cycle, emitting 24-bit ANSI escapes via `darshana`. Capability-bounded: no file I/O, no network, no fork/exec.

Position in the AGNOS userland: founder of the **pipe-decorator family** (see [shared-crates.md § Pipe-decorator family](https://github.com/MacCracken/agnosticos/blob/main/docs/development/planning/shared-crates.md)). Sibling-not-overlap with the terminal-aesthetics quintet (those produce their own output; pipe-decorators are pure filters on what passes through them).

## v1.0 Criteria

Tagged when **all** of the following hold:

- [x] **Public CLI surface frozen** — every flag documented, every flag exercised in tests, every flag behavior matches docs *— shipped at M7 / v0.8.0; refreshed `print_usage`, three ADRs (0001/0002/0003), `docs/guides/integrating-anuenue.md`, and eight runnable examples land the contract*
- [x] **UTF-8 correct by default** — grapheme-cluster aware cycling (Ruby lolcat got this wrong; AGNOS ships it right) *— shipped at M3 / v0.4.0; practical-subset classifier, ADR 0003 (M7) records the trade vs full UAX #29*
- [x] **TTY-aware** — no ANSI when stdout isn't a terminal; sensible behavior with `NO_COLOR` env *— shipped at M6 / v0.7.0; isatty via darshana 0.5.3's `tty_isatty` (sandhi closeout v0.7.1); NO_COLOR / `--no-color` / stdout-not-TTY all route to MONO*
- [x] **Color-mode negotiation** — 24-bit / 256-color / 16-color / monochrome fallback per `TERM` + `COLORTERM` *— shipped at M6 / v0.7.0; four-mode taxonomy with priority chain, override via `--color <mode>`*
- [x] **Animation parity with `lolcat -a`** — cursor positioning, frame timing, signal-safe (SIGINT restores cursor) *— shipped at M4 / v0.5.0; non-blocking signalfd probe between frames, `tty_cursor_up` re-anchor, 16 ms frame interval*
- [x] **Per-character overhead measured** — benchmark showing the cost vs `cat`, tracked in `docs/benchmarks.md` *— M5 (v0.6.0) shipped scripts/perf-bench.sh as the ratchet; ASCII no-LF at 47 ns/byte, below the v0.3.0 53 ns/byte floor*
- [ ] **Dogfooded** in real AGNOS pipelines (`iam | anuenue` MOTD; `bnrmr | anuenue` banners) for at least one minor-cycle window *(blocked on first consumer wiring, anticipated post-M6)*
- [x] **Security audit pass** — `docs/audit/YYYY-MM-DD-audit.md` clean; specific checks for stdin-bytes-as-untrusted and buffer-bounds on the line buffer *— shipped at M8 / v0.8.0; [`docs/audit/2026-05-22-audit.md`](../audit/2026-05-22-audit.md), 1 HIGH (fixed in-cycle: `_render_frame` long-cluster heap overflow), 1 LOW + 8 INFO; zero HIGH+ open at the audit close*
- [x] **CHANGELOG complete** from v0.1.0 onward *— all eight cuts (v0.1.0 → v0.7.1) sectioned; maintained at every cut*
- [ ] **Downstream gate**: at least one consumer green (likely `agnoshi` MOTD pipeline or `iam`'s default chain) *(see Dogfooded above — same blocker)*

## Dependency Map

anuenue is small enough that the dep map is the *core* of the roadmap — each milestone gates on what darshana / sakshi / vyakarana expose.

| Dep | Used At | Provides | Pin Strategy |
|-----|---------|----------|--------------|
| **darshana** | v0.2.0+ | ANSI 24-bit escape generation (`tty_fg_rgb_buf` / `tty_sgr_reset_buf`); relative cursor positioning (`tty_cursor_up` / `_down` at 0.5.2); `tty_isatty` + `tty_sgr_buf` + `tty_fg_256_buf` at 0.5.3 | Track latest stable; bump on sandhi at each minor close per [feedback_dep_lockin_sandhi_unlock](https://github.com/MacCracken/agnosticos/blob/main/.claude/projects/-home-macro-Repos-agnosticos/memory/feedback_dep_lockin_sandhi_unlock.md). Currently pinned to **0.5.3** (sandhi closeout v0.7.1). |
| **sakshi** | v0.1.0+ (required by standards) | Error type, tracing, structured logging | Tag-pinned; bump on consumer-need or sandhi. Currently 2.2.5. |
| **agnostik** | v0.1.0+ | Shared Result / Error shapes | Tag-pinned. Currently 1.2.2. |
| **Cyrius stdlib** | all | string, fmt, alloc, io, vec, str, syscalls, assert, bench, args, flags (M2+) | Toolchain pin (`cyrius.cyml [package].cyrius`). Currently 6.0.1. |

Explicitly **not** wired (evaluated and rejected for v1.0):

- **vyakarana** — evaluated at M3, rejected: it's a *source-code tokenizer* (token-kind spans for syntax highlighting via CYML grammars), not a Unicode database. anuenue ships an inline practical-subset grapheme-cluster classifier (~18 combining ranges + ZWJ + VS + RI) instead. ADR 0003 (planned M7) will record the trade vs full UAX #29.
- **abaco** — math/expression eval. HSV→RGB is ~10 lines inline; pulling abaco is overkill. Revisit only if a second pipe-decorator wants shared color math.
- **ranga** — image-processing color conversion. Wrong substrate shape — anuenue is per-character at terminal output, not pixel-buffer manipulation. Possible v2+ dep if anuenue grows an image-input mode (it shouldn't).
- **kashi** — PSF font rendering. Wrong domain — anuenue tints existing glyphs, doesn't draw them.

## Current focus

**Next slot: v1.0.0 — GA tag.** Surface frozen at v0.8.0;
capability baseline recorded by the M8 audit; documentation set
complete; eight prior cuts gated by tests + goldens + animate-
smoke + perf-bench. The two remaining v1.0 acceptance items are
*Dogfooded* and *Downstream gate* — both blocked on at least one
external consumer (likely `agnoshi` MOTD pipeline or `iam`)
wiring anuenue in for a minor-cycle soak window. Tagged on user
signal per
[feedback_no_unprompted_version_bumps](https://github.com/MacCracken/agnosticos/blob/main/.claude/projects/-home-macro-Repos-agnosticos/memory/feedback_no_unprompted_version_bumps.md).

**Shipped:** M0 (v0.1.0) → M1 (v0.2.0) → M2 (v0.3.0) → M3 (v0.4.0)
→ M4 (v0.5.0) → M5 (v0.6.0) → M6 (v0.7.0) → sandhi closeout
(v0.7.1) → M7 (docs) + M8 (audit) (v0.8.0) → **quality slot
(v0.9.0)**. See the per-milestone entries below for delivered
surface.

**Remaining to v1.0:** consumer soak window → v1.0.0 tag on
user signal.

## Milestones

### Shipped — M0 through M8

Full per-cut narratives live in [`CHANGELOG.md`](../../CHANGELOG.md);
this table is just the index.

| Cut      | Slot                            | Headline                                                                                                                |
|----------|---------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| v0.1.0   | M0 — Scaffold                   | `cyrius init anuenue` scaffold; doc tree; deps pinned (darshana 0.5.0, sakshi 2.2.5, agnostik 1.2.2).                    |
| v0.2.0   | M1 — Minimum Viable Filter      | stdin → stdout per-byte 24-bit rainbow via darshana 0.5.1's `tty_fg_rgb_buf`. Pipe-pure: read+write+brk+exit only.       |
| v0.3.0   | M2 — Flag Surface               | `-h` / `-V` / `-p` / `-s` / `-F` via `lib/flags.cyr`; deterministic-seed golden harness.                                 |
| v0.4.0   | M3 — UTF-8 Grapheme Awareness   | Cycle by cluster, not byte. Practical-subset extending-cp classifier + ZWJ + RI latches + chunk-boundary carry.         |
| v0.5.0   | M4 — Animation Mode             | `-a` / `-d` / `-S`; cluster pre-tag + 16 ms frame loop + non-blocking signalfd + darshana 0.5.2 `tty_cursor_up`.        |
| v0.6.0   | M5 — Performance Pass           | ASCII short-circuit + binary-searched `cp_is_extending` LUT + 1 530-entry phase-cached escape buffer. 91.6 → 47.0 ns/B. |
| v0.7.0   | M6 — Color-Mode Negotiation     | TRUECOLOR / 256 / 16 / MONO with priority chain; `--no-color` / `--force-color` / `--color <mode>` flags.               |
| v0.7.1   | Sandhi closeout                 | darshana 0.5.3 swap (`tty_isatty` / `tty_sgr_buf` / `tty_fg_256_buf`); stand-ins removed; DCE cap raised 350 → 512 KB.   |
| v0.8.0   | M7 + M8 — Docs + Audit          | Three ADRs (pipe-purity / HSV-inline / grapheme-cluster), integration guide, 8 examples, refreshed `print_usage`. M8 audit found + fixed one HIGH (`_render_frame` long-cluster heap overflow); zero HIGH+ open. |
| v0.9.0   | Quality slot                    | `fuzz/` populated with 5 harnesses (1.35M assertions, CI-gated). `animate-smoke.sh` extended to `--color=256` + `--color=16`. M0-anticipated `src/hsv.cyr` split landed. 5 pre-existing main.cyr lint warnings cleared. DCE binary byte-identical at 351 200 B. |

### v1.0.0 — GA

Public API contract frozen. Dep pins set for the v1.x line. Dogfood-soak window proven. Tagged on user-driven release per [feedback_no_unprompted_version_bumps](https://github.com/MacCracken/agnosticos/blob/main/.claude/projects/-home-macro-Repos-agnosticos/memory/feedback_no_unprompted_version_bumps.md).

## Out of Scope (for v1.0)

Capture what's deliberately NOT in scope — keeps future contributors from adding to v1.0 by accident.

- **File-input mode** (`anuenue file.txt`). Use `cat file.txt | anuenue`. Pipe purity is the design.
- **Image input** — wrong domain; anuenue is for terminal text. (If image-rainbow ever wants to exist, it's a different tool consuming `ranga`.)
- **Custom palettes** beyond HSV cycle. ROYGBIV is the brand; if other palettes ship, post-1.0.
- **Configuration file**. The CLI flags are the surface. No `~/.anuenue.cyml`.
- **Themes / output styles** beyond color. No bold, no italic, no underline injection. ANSI fg only.
- **Network features** — there are none. Don't add any.

## Pipe-Decorator Family Successors (post-1.0, idea-tier)

When anuenue ships, the pipe-decorator family exists as a category. Possible siblings (idea-stage, no commitments — captured in [shared-crates.md](https://github.com/MacCracken/agnosticos/blob/main/docs/development/planning/shared-crates.md) when they earn entries):

- `boxes`-equivalent — wrap stdin in ASCII borders (Sanskrit naming TBD)
- `cowsay`-equivalent — ASCII speech bubble (cultural anchor TBD)
- `pv`-equivalent — pipe-viewer with throughput indicator

These are not commitments — they're a shape-of-future-family marker, so the v1.0 architectural decisions leave room for sibling tools.
