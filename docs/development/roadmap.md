# anuenue — Roadmap

> Milestone plan through v1.0. State lives in [`state.md`](state.md);
> this file is the sequencing — what ships, in what order, against
> what dependency gates.

## What anuenue is

A Cyrius-native `lolcat` equivalent. Pure stdin → stdout pipe filter that tints each character (or grapheme cluster, post-M3) along an HSV cycle, emitting 24-bit ANSI escapes via `darshana`. Capability-bounded: no file I/O, no network, no fork/exec.

Position in the AGNOS userland: founder of the **pipe-decorator family** (see [shared-crates.md § Pipe-decorator family](https://github.com/MacCracken/agnosticos/blob/main/docs/development/planning/shared-crates.md)). Sibling-not-overlap with the terminal-aesthetics quintet (those produce their own output; pipe-decorators are pure filters on what passes through them).

## v1.0 Criteria

Tagged when **all** of the following hold:

- [ ] **Public CLI surface frozen** — every flag documented, every flag exercised in tests, every flag behavior matches docs
- [ ] **UTF-8 correct by default** — grapheme-cluster aware cycling (Ruby lolcat got this wrong; AGNOS ships it right)
- [ ] **TTY-aware** — no ANSI when stdout isn't a terminal; sensible behavior with `NO_COLOR` env
- [ ] **Color-mode negotiation** — 24-bit / 256-color / 16-color / monochrome fallback per `TERM` + `COLORTERM`
- [ ] **Animation parity with `lolcat -a`** — cursor positioning, frame timing, signal-safe (SIGINT restores cursor)
- [ ] **Per-character overhead measured** — benchmark showing the cost vs `cat`, tracked in `docs/benchmarks.md`
- [ ] **Dogfooded** in real AGNOS pipelines (`iam | anuenue` MOTD; `bnrmr | anuenue` banners) for at least one minor-cycle window
- [ ] **Security audit pass** — `docs/audit/YYYY-MM-DD-audit.md` clean; specific checks for stdin-bytes-as-untrusted and buffer-bounds on the line buffer
- [ ] **CHANGELOG complete** from v0.1.0 onward
- [ ] **Downstream gate**: at least one consumer green (likely `agnoshi` MOTD pipeline or `iam`'s default chain)

## Dependency Map

anuenue is small enough that the dep map is the *core* of the roadmap — each milestone gates on what darshana / sakshi / vyakarana expose.

| Dep | Used At | Provides | Pin Strategy |
|-----|---------|----------|--------------|
| **darshana** | v0.2.0+ | ANSI 24-bit escape generation; cursor positioning (v0.5+); color-mode capability probing (v0.7+) | Track latest stable; bump on sandhi at each minor close per [feedback_dep_lockin_sandhi_unlock](https://github.com/MacCracken/agnosticos/blob/main/.claude/projects/-home-macro-Repos-agnosticos/memory/feedback_dep_lockin_sandhi_unlock.md) |
| **sakshi** | v0.1.0+ (required by standards) | Error type, tracing, structured logging | Tag-pinned; bump on consumer-need or sandhi |
| **agnostik** | v0.1.0+ | Shared Result / Error shapes | Tag-pinned |
| **vyakarana** | v0.4.0 candidate | UTF-8 grapheme-cluster boundary detection (or use Cyrius stdlib utf8 helpers if sufficient) | Evaluate at M3 |
| **Cyrius stdlib** | all | string, fmt, alloc, io, vec, str, syscalls, assert, bench | Toolchain pin in cyrius.cyml |

Explicitly **not** wired (evaluated and rejected for v1.0):

- **abaco** — math/expression eval. HSV→RGB is ~10 lines inline; pulling abaco is overkill. Revisit only if a second pipe-decorator wants shared color math.
- **ranga** — image-processing color conversion. Wrong substrate shape — anuenue is per-character at terminal output, not pixel-buffer manipulation. Possible v2+ dep if anuenue grows an image-input mode (it shouldn't).
- **kashi** — PSF font rendering. Wrong domain — anuenue tints existing glyphs, doesn't draw them.

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

### M2 — Flag Surface (v0.3.0)

Mirror lolcat's flag surface, AGNOS-flavored:

- `-s <seed>` — color seed (deterministic output for tests)
- `-p <freq>` — palette frequency (controls phase advance per character)
- `-h` / `--help` — usage
- `-V` / `--version` — version (from cyrius.cyml `${file:VERSION}`)
- `-F <offset>` — phase offset start (Ruby lolcat compat)

Flag parser: lightweight inline; defer adding a flag-parsing lib unless a second consumer wants the same surface.

**Acceptance**: every flag exercised in `tests/anuenue.tcyr`; deterministic-seed test passes; `--help` output stable.

### M3 — UTF-8 Grapheme Awareness (v0.4.0)

Cycle by grapheme cluster, not byte. Multi-byte UTF-8 characters (and combining sequences, ZWJ emoji clusters) get one phase advance, not N.

- Evaluate `vyakarana` vs Cyrius stdlib utf8 helpers for grapheme-cluster boundary detection
- If vyakarana wins: add `[deps.vyakarana]` and bump pin
- Test corpus: ASCII (regression), Cyrillic, CJK, combining diacritics, emoji ZWJ sequences
- Document the rule: invalid UTF-8 bytes get cycled-byte-at-a-time (graceful degradation, never panic)

**Acceptance**: Unicode test corpus passes; phase advance count matches grapheme count, not byte count.

**Dep gate**: either vyakarana ships the grapheme-cluster API, or stdlib utf8 is sufficient.

### M4 — Animation Mode (v0.5.0)

`-a` (animate) + `-d <duration>` + `-S <speed>` — the lolcat animation experience.

- Cursor positioning via `darshana::cursor` (save/restore, move-up, clear-line)
- Frame loop: render → sleep → repaint with phase advance
- SIGINT handler: restore cursor + terminal state before exit
- Frame timing: precise enough that 16ms intervals don't drift over minutes

**Acceptance**: `cat poem.txt | ./build/anuenue -a -d 5` renders 5s of animation, ends cleanly, leaves terminal sane after SIGINT.

**Dep gate**: darshana::cursor stable; Cyrius stdlib sleep / signal handling sufficient.

### M5 — Performance Pass (v0.6.0)

Get per-character overhead invisible vs `cat`.

- Profile `cat largefile | anuenue > /dev/null` — find allocations in the hot path, kill them
- Pre-compute ANSI escape templates where possible (24-bit `\x1b[38;2;R;G;Bm` is 19 chars + 3 ints)
- Single write per line (vs per-character) — batch into the line buffer
- 3-point benchmark trend (baseline → optimized → current) captured in `docs/benchmarks.md`

**Acceptance**: `cat 10mb-file | anuenue > /dev/null` overhead under target threshold (set at M5 baseline) vs `cat 10mb-file > /dev/null`.

### M6 — Color-Mode Negotiation (v0.7.0)

Be a good citizen on every terminal.

- 24-bit (default on modern terms): emit `\x1b[38;2;R;G;Bm` directly
- 256-color fallback: HSV → 6×6×6 cube + 24-step grayscale ramp
- 16-color fallback: 8 base + 8 bright; mood-preserving quantization
- Monochrome: stdout-not-tty OR `NO_COLOR` env OR `--no-color` flag → pass-through `cat`
- `TERM` / `COLORTERM` env probing via darshana

**Acceptance**: tests cover all four modes (mock-TTY harness); `NO_COLOR=1 echo X | anuenue` is byte-identical to `echo X`.

**Dep gate**: darshana color-capability probing surface.

### M7 — Public-Surface Freeze + Guide Docs (v0.8.0)

API/CLI contract freeze + downstream-consumer documentation.

- `docs/guides/integrating-anuenue.md` — how MOTD pipelines compose with anuenue
- `docs/examples/` — runnable Cyrius programs showing pipe composition
- `docs/adr/0001-pipe-purity.md` — why no file I/O
- `docs/adr/0002-hsv-inline-not-abaco.md` — why HSV→RGB stays inline
- `docs/adr/0003-grapheme-cluster-cycling.md` — why we deviate from byte-level

**Acceptance**: every flag documented in `docs/guides/`; every public symbol cited from at least one example.

### M8 — Security Audit + Closeout (v0.9.0)

P(-1) hardening pass before the v1.0 freeze.

- Full security checklist: input validation, buffer bounds, syscall review, pointer paths, command-injection grep, path-traversal grep
- Findings → `docs/audit/2026-XX-XX-audit.md` with severity tags
- All HIGH+ findings closed before v1.0 tag
- Closeout-pass checklist (see CLAUDE.md § Closeout Pass) all green
- Sandhi-fold any drifted deps (darshana / sakshi / vyakarana) to current GA

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
