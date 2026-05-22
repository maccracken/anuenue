# anuenue — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.1.0** — scaffolded 2026-05-21 via `cyrius init anuenue`. No releases yet.

## Phase

**M0 (scaffold complete)** → next slot is **M1 — Minimum Viable Filter (v0.2.0)** per [roadmap.md](roadmap.md). M1 is the pipe-purity proof: stdin → stdout, byte-level cycling, 24-bit ANSI via darshana.

## Toolchain

- **Cyrius pin**: `6.0.1` (in `cyrius.cyml [package].cyrius`)
- Pin-lag spectrum: matches darshana 0.5.0 / sakshi 2.2.5 / agnostik 1.2.2 — all on 6.0.1; no lag at scaffold.

## Source

Initial scaffold only. `src/main.cyr` is the `cyrius init` hello-world; no anuenue logic yet.

- `src/main.cyr` — entry stub
- `src/test.cyr` — top-level test entry stub (referenced by `cyrius.cyml [build].test`)

Module split planned at M1 — likely `src/hsv.cyr` (HSV→RGB inline math) + `src/filter.cyr` (stdin→stdout loop) + `src/main.cyr` (argv + driver). Defer until the code earns it.

## Binary

- **Size**: TBD at first M1 build (DCE on)
- **Output path**: `build/anuenue`

## Tests

- `tests/anuenue.tcyr` — primary suite (scaffold-state: empty; first cases land at M1)
- `tests/anuenue.bcyr` — benchmark (scaffold-state: empty; first bench lands at M1)
- `tests/anuenue.fcyr` — fuzz stub (scaffold-state: empty; first harness lands at M2+ when flag parser exists)

Assertion count: **0** (scaffold). Target by M1: 20+ across smoke, line-cycle, HSV-math, byte-boundary.

## Dependencies

Direct (declared in `cyrius.cyml`):

| Dep | Tag | Role | Status |
|-----|-----|------|--------|
| `darshana` | 0.5.0 | ANSI color escape generation | Stable, scoped to fg_rgb path at M1 |
| `sakshi` | 2.2.5 | Errors / tracing / structured logging | Standard wiring per first-party-standards |
| `agnostik` | 1.2.2 | Shared Result / Error shapes | Standard wiring |
| Cyrius stdlib | n/a | string, fmt, alloc, io, vec, str, syscalls, assert, bench | Auto-resolved via `cyrius deps` |

No pre-release / pre-1.0 deps on the critical path. No external (non-AGNOS) deps.

## Verification Hosts

| Host | Role | Status |
|------|------|--------|
| `archaemenid` (Beelink SER, AMD Zen) | Primary dev box; will be the iron-soak target once AGNOS userland boots there | Not yet (anuenue runs on host Linux for now) |
| Host Linux (CI runner pattern) | Build + test gate via `.github/workflows/ci.yml` | Active from M0 |

## Consumers

_None yet._

Anticipated at v0.7+:
- `agnoshi` — MOTD pipeline composition
- `iam` — default login splash chain (`iam | anuenue`)
- end-user shells — bash / zsh / agnoshi interactive use

## Carry-Forward

_(Slot debt that bleeds across minors. Empty at scaffold.)_

## Next

See [roadmap.md § M1](roadmap.md#m1--minimum-viable-filter-v020).
