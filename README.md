# anuenue

> **ānuenue** — Hawaiian for *rainbow*. Stdin → stdout rainbow-tint pipe filter.
> The Cyrius-native `lolcat`.

Pure pipe-filter: no file I/O, no network, no fork/exec. Tints each character along an HSV cycle, emits 24-bit ANSI via [`darshana`](https://github.com/MacCracken/darshana), and gets out of the way.

## Quick Start

```sh
cyrius deps                                  # resolve sibling deps (darshana, sakshi, agnostik)
cyrius build src/main.cyr build/anuenue      # build
cyrius test                                  # [build].test + tests/*.tcyr
```

## Usage

```sh
echo "AGNOS" | ./build/anuenue           # one-shot rainbow tint
echo "AGNOS" | ./build/anuenue -s 100    # deterministic seed (testing / scripts)
echo "AGNOS" | ./build/anuenue -p 13     # bigger phase step per character
iam | ./build/anuenue                    # rainbow system-info splash
bnrmr "AGNOS" | ./build/anuenue          # rainbow banner
./build/anuenue --version                # anuenue 0.4.0
./build/anuenue --help                   # full flag surface
```

**Flags shipped at v0.4.0**: `-h`/`--help`, `-V`/`--version`, `-p`/`--freq <N>` (phase step per cluster; default 7), `-s`/`--seed <N>` (starting hue phase — deterministic-output hook), `-F`/`--offset <N>` (additive phase offset, Ruby-lolcat compat).

**UTF-8 / grapheme behavior**: cycle advances per *cluster*, not per byte. CJK / combining diacritics / ZWJ emoji sequences / regional-indicator flag pairs all get one phase advance each. Invalid UTF-8 → graceful per-byte cycling (never panics).

**Coming in v0.5.0 (M4)**: `-a` / `-d <duration>` / `-S <speed>` animation mode. See [`docs/development/roadmap.md`](docs/development/roadmap.md).

## Why a Cyrius-native lolcat?

`lolcat` exists in every Linux distro as a `gem install lolcat` / `apt install lolcat` afterthought. In AGNOS, the rainbow filter is **first-party** — sovereign-stack, no Ruby runtime, capability-bounded, UTF-8 grapheme-aware (a thing the Ruby implementation got wrong for years), pinned and dogfooded alongside the rest of the userland.

It's also the founder of the **pipe-decorator family** in AGNOS userland — stdin → stdout aesthetic / transform filters, distinct from the terminal-aesthetics quintet (`cmdrs` / `darshini` / `iam` / `bnrmr` / `hapi`) which produce their own output.

## Project Status

**v0.4.0 — M3: UTF-8 Grapheme Awareness.** Pipe-purity proof (M1) + lolcat-equivalent flag surface (M2) + grapheme-cluster cycling (M3) all shipped. Next slot is **M4 — Animation Mode (v0.5.0)**. See [`docs/development/roadmap.md`](docs/development/roadmap.md) for the v1.0 plan and [`docs/development/state.md`](docs/development/state.md) for the live snapshot.

## Documentation

- [`CLAUDE.md`](CLAUDE.md) — durable rules for Claude Code working in this repo
- [`docs/development/roadmap.md`](docs/development/roadmap.md) — milestones through v1.0
- [`docs/development/state.md`](docs/development/state.md) — current state (volatile)
- [`docs/adr/`](docs/adr/) — architecture decision records
- [`docs/architecture/`](docs/architecture/) — non-obvious constraints
- [`docs/guides/`](docs/guides/) — task-oriented how-tos
- [`docs/examples/`](docs/examples/) — runnable examples
- [`CHANGELOG.md`](CHANGELOG.md) — release log (Keep a Changelog format)

## Standards

This project follows the AGNOS [First-Party Standards](https://github.com/MacCracken/agnosticos/blob/main/docs/development/planning/first-party-standards.md) and [First-Party Documentation](https://github.com/MacCracken/agnosticos/blob/main/docs/development/planning/first-party-documentation.md). It is part of the [agnosticos](https://github.com/MacCracken/agnosticos) genesis-repo's userland.

## License

GPL-3.0-only
