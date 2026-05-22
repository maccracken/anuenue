# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
