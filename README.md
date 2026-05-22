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

## Usage (when M1 lands)

```sh
echo "AGNOS" | ./build/anuenue           # one-shot rainbow tint
iam | ./build/anuenue                    # rainbow system-info splash
bnrmr "AGNOS" | ./build/anuenue          # rainbow banner
cat poem.txt | ./build/anuenue -a -d 5   # 5s animated mode
```

## Why a Cyrius-native lolcat?

`lolcat` exists in every Linux distro as a `gem install lolcat` / `apt install lolcat` afterthought. In AGNOS, the rainbow filter is **first-party** — sovereign-stack, no Ruby runtime, capability-bounded, UTF-8 grapheme-aware (a thing the Ruby implementation got wrong for years), pinned and dogfooded alongside the rest of the userland.

It's also the founder of the **pipe-decorator family** in AGNOS userland — stdin → stdout aesthetic / transform filters, distinct from the terminal-aesthetics quintet (`cmdrs` / `darshini` / `iam` / `bnrmr` / `hapi`) which produce their own output.

## Project Status

**v0.1.0 — Scaffold.** Repo exists, deps wired, docs scaffolded, build pipeline green. No filter logic yet — see [`docs/development/roadmap.md`](docs/development/roadmap.md) for the M0 → v1.0 plan and [`docs/development/state.md`](docs/development/state.md) for the live snapshot.

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
