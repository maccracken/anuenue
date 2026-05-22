# Getting started with anuenue

## Build

```sh
cyrius deps                                    # resolve sibling deps (darshana, sakshi, agnostik)
cyrius build src/main.cyr build/anuenue        # compile (add CYRIUS_DCE=1 for release builds)
cyrius test                                    # run [build].test + tests/*.tcyr
cyrius bench tests/anuenue.bcyr                # hot-path micro-benchmarks
sh scripts/golden-check.sh                     # determinism / byte-identical output regression
```

## Run

anuenue is a pipe filter: stdin → tinted stdout. No file-input mode (use `cat file | anuenue`), no themes, no config file.

```sh
echo "AGNOS" | ./build/anuenue                 # one-shot rainbow tint
echo "AGNOS" | ./build/anuenue -s 100          # deterministic output (-s seeds the hue)
echo "日本AGNOS" | ./build/anuenue              # UTF-8 cluster-aware (one phase per glyph)
iam | ./build/anuenue                          # MOTD pipeline composition
./build/anuenue --version                      # anuenue 0.4.0
./build/anuenue --help                         # full flag listing
```

### Flag surface (v0.3.0+)

| Flag | Long form | Arg | Effect |
|------|-----------|-----|--------|
| `-h` | `--help` | — | Usage to stderr, exit 0 |
| `-V` | `--version` | — | `anuenue X.Y.Z\n` to stdout, exit 0 |
| `-p` | `--freq <N>` | int | Phase step per cluster (default 7 — bigger = tighter rainbow) |
| `-s` | `--seed <N>` | int | Starting hue phase. Deterministic-output hook used by the golden fixtures |
| `-F` | `--offset <N>` | int | Additive phase offset (Ruby-lolcat compat). `PHASE_START = seed + offset` |

`-s` and `-F` are **additive** so they compose without precedence surprises. Bad / unknown / missing-value flags exit 2 with a specific message followed by usage.

### Grapheme behavior (v0.4.0+)

Phase advances **per grapheme cluster**, not per byte. Practical effect:

- CJK / Cyrillic / Hebrew / Arabic codepoints: one phase advance per glyph (vs N for the byte count)
- `é` written as base `e` + combining acute (U+0301): one phase advance
- Emoji ZWJ sequences (`👨‍👩‍👧`): one phase advance for the whole family
- Regional-indicator pairs (`🇺🇸`): one phase advance for the flag
- Invalid UTF-8: graceful per-byte cycling (never panics, never over-reads)

Practical-subset classifier — see [`../development/roadmap.md`](../development/roadmap.md) § M3 for the trade vs full UAX #29.

## Layout

- `src/main.cyr` — entry point. Top-level `var r = main(); syscall(SYS_EXIT, r);`. Argv → flag parse → filter dispatch.
- `src/filter.cyr` — testable library surface. HSV→RGB geometry, UTF-8 primitives, cluster state machine, `anuenue_filter()` loop.
- `src/version_str.cyr` — **auto-generated** by `scripts/version-bump.sh`. Never hand-edit.
- `src/test.cyr` — top-level test entry referenced by `cyrius.cyml [build].test`. Real assertions live in `tests/anuenue.tcyr`.
- `tests/anuenue.tcyr` — primary test suite (`cyrius test` auto-discovers).
- `tests/anuenue.bcyr` — benchmarks (`cyrius bench`).
- `tests/anuenue.fcyr` — fuzz harness stub (no live cases yet — see [`../development/state.md`](../development/state.md) § Carry-Forward).
- `tests/golden/*.out` — committed byte-identical fixtures asserted by `scripts/golden-check.sh` + CI.

## Adding a feature

1. Edit `src/filter.cyr` (filter / UTF-8 / HSV logic) or `src/main.cyr` (entrypoint / argv handling).
2. Add a test case to `tests/anuenue.tcyr`. If the change affects observable output, add a golden fixture under `tests/golden/` and a matching `check_golden` call in `scripts/golden-check.sh`.
3. Run `cyrius test && sh scripts/golden-check.sh`.
4. If perf-relevant: `cyrius bench tests/anuenue.bcyr` and update `docs/benchmarks.md`.
5. CHANGELOG entry in `[Unreleased]`. Version bump (`sh scripts/version-bump.sh X.Y.Z`) happens at cycle open / close — see CLAUDE.md.

See [`../adr/template.md`](../adr/template.md) when a non-trivial design choice deserves an ADR.

## Releasing

Cycle close is user-driven:

1. CHANGELOG `[Unreleased]` body → moved into `[X.Y.Z] — YYYY-MM-DD` section.
2. `sh scripts/version-bump.sh X.Y.Z` (updates VERSION, regenerates `src/version_str.cyr`, inserts CHANGELOG header).
3. `docs/development/state.md` — refresh Version row narrative + Binary row size.
4. Closeout-pass per CLAUDE.md (clean rebuild, tests, lint, goldens, version consistency).
5. User commits + tags `X.Y.Z` + pushes — `.github/workflows/release.yml` runs the version-verify gate and ships artifacts.
