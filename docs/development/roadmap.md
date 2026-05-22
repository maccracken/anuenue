# anuenue — Roadmap

> Milestone plan through v1.0. State lives in [`state.md`](state.md);
> this file is the sequencing — what ships, in what order, against
> what dependency gates.

## What anuenue is

A Cyrius-native `lolcat` equivalent. Pure stdin → stdout pipe filter that tints each character (or grapheme cluster, post-M3) along an HSV cycle, emitting 24-bit ANSI escapes via `darshana`. Capability-bounded: no file I/O, no network, no fork/exec.

Position in the AGNOS userland: founder of the **pipe-decorator family** (see [shared-crates.md § Pipe-decorator family](https://github.com/MacCracken/agnosticos/blob/main/docs/development/planning/shared-crates.md)). Sibling-not-overlap with the terminal-aesthetics quintet (those produce their own output; pipe-decorators are pure filters on what passes through them).

## v1.0 Criteria

Tagged when **all** of the following hold:

- [ ] **Public CLI surface frozen** — every flag documented, every flag exercised in tests, every flag behavior matches docs *(M2 shipped the surface at v0.3.0; freeze happens at M7)*
- [x] **UTF-8 correct by default** — grapheme-cluster aware cycling (Ruby lolcat got this wrong; AGNOS ships it right) *— shipped at M3 / v0.4.0; practical-subset classifier, ADR 0003 (M7) records the trade vs full UAX #29*
- [ ] **TTY-aware** — no ANSI when stdout isn't a terminal; sensible behavior with `NO_COLOR` env *(M6)*
- [ ] **Color-mode negotiation** — 24-bit / 256-color / 16-color / monochrome fallback per `TERM` + `COLORTERM` *(M6)*
- [ ] **Animation parity with `lolcat -a`** — cursor positioning, frame timing, signal-safe (SIGINT restores cursor) *(M4)*
- [~] **Per-character overhead measured** — benchmark showing the cost vs `cat`, tracked in `docs/benchmarks.md` *(baseline + M3 regression captured; M5 sets the production budget)*
- [ ] **Dogfooded** in real AGNOS pipelines (`iam | anuenue` MOTD; `bnrmr | anuenue` banners) for at least one minor-cycle window *(blocked on first consumer wiring, anticipated post-M6)*
- [ ] **Security audit pass** — `docs/audit/YYYY-MM-DD-audit.md` clean; specific checks for stdin-bytes-as-untrusted and buffer-bounds on the line buffer *(M8)*
- [x] **CHANGELOG complete** from v0.1.0 onward *— v0.1.0 / v0.2.0 / v0.3.0 / v0.4.0 all sectioned; maintained at every cut*
- [ ] **Downstream gate**: at least one consumer green (likely `agnoshi` MOTD pipeline or `iam`'s default chain) *(see Dogfooded above — same blocker)*

## Dependency Map

anuenue is small enough that the dep map is the *core* of the roadmap — each milestone gates on what darshana / sakshi / vyakarana expose.

| Dep | Used At | Provides | Pin Strategy |
|-----|---------|----------|--------------|
| **darshana** | v0.2.0+ | ANSI 24-bit escape generation (`tty_fg_rgb_buf` / `tty_sgr_reset_buf`); cursor positioning (M4); color-mode capability probing (M6) | Track latest stable; bump on sandhi at each minor close per [feedback_dep_lockin_sandhi_unlock](https://github.com/MacCracken/agnosticos/blob/main/.claude/projects/-home-macro-Repos-agnosticos/memory/feedback_dep_lockin_sandhi_unlock.md). Currently pinned to 0.5.1 (M1 truecolor unlock). |
| **sakshi** | v0.1.0+ (required by standards) | Error type, tracing, structured logging | Tag-pinned; bump on consumer-need or sandhi. Currently 2.2.5. |
| **agnostik** | v0.1.0+ | Shared Result / Error shapes | Tag-pinned. Currently 1.2.2. |
| **Cyrius stdlib** | all | string, fmt, alloc, io, vec, str, syscalls, assert, bench, args, flags (M2+) | Toolchain pin (`cyrius.cyml [package].cyrius`). Currently 6.0.1. |

Explicitly **not** wired (evaluated and rejected for v1.0):

- **vyakarana** — evaluated at M3, rejected: it's a *source-code tokenizer* (token-kind spans for syntax highlighting via CYML grammars), not a Unicode database. anuenue ships an inline practical-subset grapheme-cluster classifier (~18 combining ranges + ZWJ + VS + RI) instead. ADR 0003 (planned M7) will record the trade vs full UAX #29.
- **abaco** — math/expression eval. HSV→RGB is ~10 lines inline; pulling abaco is overkill. Revisit only if a second pipe-decorator wants shared color math.
- **ranga** — image-processing color conversion. Wrong substrate shape — anuenue is per-character at terminal output, not pixel-buffer manipulation. Possible v2+ dep if anuenue grows an image-input mode (it shouldn't).
- **kashi** — PSF font rendering. Wrong domain — anuenue tints existing glyphs, doesn't draw them.

## Current focus

**Next slot: M4 — Animation Mode (v0.5.0).** `-a` / `-d <duration>` /
`-S <speed>` + cursor positioning + SIGINT cursor-restore. Dep gate:
`darshana::cursor` (already exposed in 0.5.x, no sandhi bump needed
unless the SIGINT-safe restore primitives land elsewhere).

**Shipped:** M0 (v0.1.0) → M1 (v0.2.0) → M2 (v0.3.0) → M3 (v0.4.0).
See the per-milestone entries below for delivered surface.

**Remaining to v1.0:** M4 (animation) → M5 (perf) → M6 (color-mode
negotiation) → M7 (surface freeze + ADRs) → M8 (security closeout) →
v1.0.0 (tag on user signal).

## Milestones

### M0 — Scaffold (v0.1.0) — ✅ shipped 2026-05-21

- `cyrius init anuenue` scaffold landed (cyrius 6.0.1)
- Deps wired: darshana 0.5.0, sakshi 2.2.5, agnostik 1.2.2
- Doc tree per [first-party-documentation.md](https://github.com/MacCracken/agnosticos/blob/main/docs/development/planning/first-party-documentation.md)
- CLAUDE.md filled from example template; roadmap (this file); state.md initial snapshot
- Build path verified — `cyrius deps && cyrius build` produces a runnable binary
- No filter logic yet; `src/main.cyr` is the scaffold hello-world

**Acceptance**: `cyrius build` succeeds, `cyrius test` passes, README is the AGNOS-style first impression.

### M1 — Minimum Viable Filter (v0.2.0) — ✅ shipped 2026-05-21

The pipe-purity proof: stdin → stdout, byte-level cycling, 24-bit ANSI via darshana. No flags. No animation. No UTF-8 cluster awareness. Just the core loop.

Shipped surface:

- `src/filter.cyr` — `hsv_rainbow(phase, out_rgb)` (integer 6-sector geometry over a 1530-unit phase space) + `anuenue_filter()` (stdin→stdout loop with LF-flush + force-flush). `src/main.cyr` is the entrypoint shell.
- Emits via darshana 0.5.1's new `tty_fg_rgb_buf` + `tty_sgr_reset_buf` — composed into a 32KB line buffer for one write(2) per line; force-flush when next-character worst-case would exceed the 22-byte reserve.
- 47 assertions across 6 groups in `tests/anuenue.tcyr`; first micro-benchmarks in `tests/anuenue.bcyr` (hsv_rainbow ≈8 ns/call, tty_fg_rgb_buf ≈45 ns/call); end-to-end baseline in `docs/benchmarks.md` (~53 ns/byte over cat, 17.4× output expansion).
- Pipe-purity verified: capability surface is read(0) + write(1) + brk(12) + exit(60). No open, connect, fork, exec, signal, ioctl.

**Dep gate**: darshana ANSI 24-bit fg path — **delivered at darshana 0.5.1** (anuenue was the consumer asking; pre-0.5.1 darshana shipped only 8/16 named SGR colors). Sandhi-unlock pattern: anuenue's M1 drove darshana's `tty_fg_rgb` / `tty_bg_rgb` / `_buf` variants into existence.

**Acceptance** (all green): `echo "AGNOS" | ./build/anuenue` renders rainbow ASCII; `printf 'X%.0s' {1..100000} | ./build/anuenue > /dev/null` exits 0 with no OOM; baseline bench captured.

### M2 — Flag Surface (v0.3.0) — ✅ shipped 2026-05-21

Mirror lolcat's flag surface, AGNOS-flavored:

- `-s <seed>` — color seed (deterministic output for tests). Writes starting hue phase.
- `-p <freq>` — palette frequency (controls phase advance per character). Default 7.
- `-h` / `--help` — usage. Printed to stderr per POSIX; pipe-purity unaffected.
- `-V` / `--version` — version. Reads `_VERSION_STR_ANUENUE` from auto-generated `src/version_str.cyr` (cyim drift-prevention pattern); CI's Version consistency step asserts the literal vs `VERSION` file.
- `-F <offset>` — phase offset start (Ruby lolcat compat). Additive to `-s`: `PHASE_START = seed + offset`.

**Parser**: settled on `lib/flags.cyr` (AGNOS stdlib) over the
roadmap-original "lightweight inline" — the stdlib parser is what
every toolchain binary and consumer uses; adopting stdlib doesn't
trip the "don't add a flag-parsing lib" rule (which was about
sibling deps, not stdlib). Capability-surface delta: `args_init()`
opens `/proc/self/cmdline` once at startup (open(2) + read + close(3)).

**Acceptance** (all green): every flag exercised in `tests/anuenue.tcyr` (27 new assertions across 7 groups); deterministic-seed test passes via `tests/golden/agnos-rainbow-s100.out` + `scripts/golden-check.sh` (CI-wired); `--help` output stable and stderr-only.

### M3 — UTF-8 Grapheme Awareness (v0.4.0) — ✅ shipped 2026-05-21

Cycle by grapheme cluster, not byte. Multi-byte codepoints (CJK / combining diacritics / ZWJ-joined emoji / regional-indicator flag pairs) get one phase advance, not N. ASCII fast-path stays byte-identical (v0.3.0 `-s 100` golden remains green).

Shipped surface:

- **UTF-8 primitives in `src/filter.cyr`** — `utf8_seq_len()` (1/2/3/4-byte detection, 0 on truncation = chunk-boundary carry signal, 1 on invalid = graceful degradation); `utf8_decode()` (codepoint assembly); `cp_is_extending()` (practical-subset combining-mark classifier — ~18 ranges covering Latin / Cyrillic / Hebrew / Arabic combiners + ZWJ + VS + half marks + math zone + VS supplement); `cp_is_regional_indicator()` (flag-pair recognition).
- **Cluster state machine** in `anuenue_filter()` — three latches: `saw_any` (suppress pre-advance on the first cluster), `prev_was_zwj` (codepoint after ZWJ joins the cluster), `prev_unpaired_ri` (pair regional indicators into flag emoji).
- **Chunk-boundary carry** — multi-byte sequences straddling the 4 096-byte read boundary are split correctly; partial bytes carry into the next read. EOF with carry → graceful per-byte cycling.
- **30 new tcyr assertions** across 5 groups; **3 new golden fixtures** (`cjk-mixed-s0.out`, `combining-s0.out`, `zwj-flag-s0.out`); `ANUENUE_FLUSH_RESERVE` bumped 22 → 32 for 4-byte codepoint worst-case envelope.

**Dep gate resolved**: vyakarana evaluated and rejected (wrong domain — source-code tokenizer, not Unicode DB). Inline practical-subset classifier shipped instead. ADR 0003 (planned M7) will record the trade vs full UAX #29.

**Practical-subset boundaries**: Hangul L/V/T composition and some Brahmic spacing-mark sequences misclassify as advancing (errs on "more rainbow, not less"). Acceptable trade for the shipped scope; M6 / M7 may revisit if a real-world corpus reports drift.

### M4 — Animation Mode (v0.5.0) — *next*

`-a` (animate) + `-d <duration>` + `-S <speed>` — the lolcat animation experience.

- **Cursor positioning** via `darshana::cursor` (save/restore, move-up, clear-line). Confirm the 0.5.x surface covers what's needed before opening v0.5.0; sandhi-bump darshana if not.
- **Frame loop**: buffer one full-screen worth of cluster-tagged input (M3's cluster state machine re-runs per frame with `ANUENUE_PHASE_START` advanced), render, sleep, repaint. Pipe-purity caveat: animation mode buffers more than one line — document the deviation in the M7 surface-freeze ADR.
- **SIGINT handler**: restore cursor + emit `\x1b[0m` reset before exit. Capability-surface gains `rt_sigaction(13)` — call out in the security audit (M8).
- **Frame timing**: 16ms intervals via `clock_nanosleep`; drift target <1 frame over a 60-second run.

**Acceptance**: `cat poem.txt | ./build/anuenue -a -d 5` renders 5s of animation, ends cleanly, leaves terminal sane after SIGINT.

**Dep gate**: `darshana::cursor` covers save/restore + clear-line. Cyrius stdlib provides nanosleep + signal handling.

### M5 — Performance Pass (v0.6.0)

Get per-character overhead back toward the v0.3.0 floor — M3 regressed the ASCII hot path from 53 → 86 ns/byte (62%) for cluster classification. Recover most of it without giving up grapheme correctness.

- **ASCII short-circuit** — `b < 0x80` branch around `utf8_seq_len` + `cp_is_extending`. Likely 10-20 ns/byte.
- **Combining-mark lookup** — flatten the 18-range chain in `cp_is_extending` into a bitmap / binary-search LUT. Halves the per-codepoint cost on Latin combining-mark traffic.
- **Escape pre-computation** — phase-cached escape buffer (~256 entries) avoiding re-running `hsv_rainbow` + `_ansi_emit_u8` per codepoint when `phase` advances by a fixed step.
- **3-point benchmark trend** captured in `docs/benchmarks.md` (v0.3.0 baseline → M5 target → M5 final).

**Acceptance**: ASCII per-byte overhead ≤ 60 ns (close the gap to within ~15% of v0.3.0); UTF-8 corpus unaffected or better; binary size stays under 350 KB DCE.

### M6 — Color-Mode Negotiation (v0.7.0)

Be a good citizen on every terminal — anuenue currently assumes 24-bit truecolor.

- 24-bit (default on modern terms): emit `\x1b[38;2;R;G;Bm` directly — unchanged from current behavior
- 256-color fallback: HSV → 6×6×6 cube + 24-step grayscale ramp
- 16-color fallback: 8 base + 8 bright; mood-preserving quantization
- Monochrome: stdout-not-tty OR `NO_COLOR` env OR `--no-color` flag → pass-through `cat`
- `TERM` / `COLORTERM` env probing via darshana — capability surface gains `getenv` (or `/proc/self/environ` read) at startup

**Acceptance**: tests cover all four modes (mock-TTY harness); `NO_COLOR=1 echo X | anuenue` is byte-identical to `echo X`.

**Dep gate**: darshana color-capability probing surface (`tty_caps_detect` or equivalent) — currently absent, sandhi-unlock candidate for the M6 cut.

### M7 — Public-Surface Freeze + Guide Docs (v0.8.0)

API/CLI contract freeze + downstream-consumer documentation. Three ADRs queued (none written yet — see [`docs/adr/`](../adr/) status):

- `0001-pipe-purity.md` — why no file I/O / no config / no themes. The constraint that shapes everything.
- `0002-hsv-inline-not-abaco.md` — why HSV→RGB stays inline rather than pulling abaco.
- `0003-grapheme-cluster-cycling.md` — why M3 shipped a practical-subset classifier instead of full UAX #29 / vyakarana / a generated table. Includes the Hangul L/V/T trade.

Plus:

- `docs/guides/integrating-anuenue.md` — how MOTD pipelines compose with anuenue.
- `docs/examples/` — runnable Cyrius programs showing pipe composition.

**Acceptance**: every flag documented in `docs/guides/`; every public symbol cited from at least one example; all three ADRs in `Accepted` status.

### M8 — Security Audit + Closeout (v0.9.0)

P(-1) hardening pass before the v1.0 freeze.

- Full security checklist: input validation (stdin bytes treated as untrusted — already a project rule, audit makes it explicit), buffer bounds on the 32 KB line buffer + 4 KB read buffer, syscall review (verify the capability surface hasn't grown past read/write/brk/exit + open/close-for-cmdline + M4's signal additions), command-injection grep, path-traversal grep.
- Findings → `docs/audit/YYYY-MM-DD-audit.md` with severity tags.
- All HIGH+ findings closed before v1.0 tag.
- Closeout-pass checklist (see CLAUDE.md § Closeout Pass) all green.
- Sandhi-fold any drifted deps (darshana / sakshi / agnostik) to current GA.

**Acceptance**: audit doc filed; zero HIGH+ findings open; downstream build chain green against the closeout candidate.

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
