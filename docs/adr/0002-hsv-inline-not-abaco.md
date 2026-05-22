# 0002 — HSV→RGB stays inline; no abaco dependency

**Status**: Accepted
**Date**: 2026-05-22

## Context

anuenue's whole reason to exist is "tint each input character along an
HSV cycle". The HSV→RGB conversion is the *one* piece of mathematics
the binary needs. Every cluster on the hot path calls it (or, post-M5,
hits the phase cache that was built by calling it 1 530 times at
startup).

[`abaco`](https://github.com/MacCracken/abaco) is AGNOS's math /
expression-evaluation crate — first-party-standards-compliant, useful
for tools that want a general expression layer. The shared-crates
registry lists it as an option for projects that need real math.

We need to decide: does anuenue depend on abaco for HSV→RGB, or does it
ship the conversion inline?

The functional shape is small. anuenue ships only the **full-saturation,
full-value (S=V=1) rainbow** — there's no need for the general
H/S/V → R/G/B form, just the 6-sector ramp parameterised by phase. The
canonical algorithm at S=V=1 reduces to:

```
sector = phase / 255            # 0..5
t      = phase % 255            # 0..254
sector 0: R=255, G=t,   B=0
sector 1: R=255-t, G=255, B=0
sector 2: R=0,   G=255, B=t
sector 3: R=0,   G=255-t, B=255
sector 4: R=t,   G=0,   B=255
sector 5: R=255, G=0,   B=255-t
```

That's `src/hsv.cyr:58` — six branches, integer ops only, no floats,
no transcendentals. About 30 lines including the phase-wrap pre-step
(`phase % ANUENUE_PHASE_MOD`) and the boilerplate Cyrius
`store64`-to-out-buffer convention. (Lived in `src/filter.cyr` from
M1 through v0.8.0; pulled into its own file at v0.9.0 once the fuzz
harness's `emit-phase-esc` target made it a second consumer.)

## Decision

**Implement HSV→RGB inline as `hsv_rainbow(phase, out_rgb)`.** No
abaco dependency. The function originally lived in `src/filter.cyr`
alongside the filter loop that calls it (M1) and the phase-cache
builder that calls it 1 530 times at startup (M5); at v0.9.0 it
moved into its own `src/hsv.cyr` once the fuzz harness gave it a
second consumer (see Neutral consequences below for the split's
history).

The signature is the integer-only S=V=1 form:

```
fn hsv_rainbow(phase, out_rgb): i64
    # phase: 0..1529 (wraps via % ANUENUE_PHASE_MOD)
    # out_rgb: 24-byte stack buffer (3 × i64 slots — Cyrius convention)
```

abaco stays in the candidate pool for **post-v1.0 reconsideration**.
The revisit trigger is documented below.

## Consequences

### Positive

- **Zero added dep weight.** anuenue's dep graph is darshana + sakshi +
  agnostik + Cyrius stdlib. Each new dep is an audit obligation, a pin-
  management burden, and a sandhi-coordination cost. 30 lines of
  integer math doesn't earn its keep.
- **Auditable.** A reader can verify the algorithm against any HSV→RGB
  reference (Wikipedia's HSL/HSV article, the original Smith 1978
  paper) in 5 minutes. No need to chase indirection through abaco's
  expression evaluator.
- **Performance.** Inline integer-only branches are exactly what the
  M5 perf pass needed for the phase-cache build (1 530 calls at
  startup, ~80 μs). Calling out to abaco would force a function
  boundary on the hot construction path. Once the cache is built, the
  per-cluster cost is a memcpy from a pre-formatted escape buffer
  (`_emit_phase_esc` at `src/filter.cyr:153`) — abaco wouldn't help
  here anyway.
- **No floating point.** The S=V=1 rainbow lives entirely in integers
  in `[0, 255]`. Pulling abaco would introduce float-shaped APIs that
  we'd then have to round. Inline integer ops bypass the question.
- **DCE cooperates.** anuenue's `cyrius build` with `CYRIUS_DCE=1`
  drops 1 240 unreachable fns; if `hsv_rainbow` were behind an abaco
  call, DCE would either pull abaco's expression machinery in
  (bloating the binary) or leave it stubbed and we'd debug "expression
  not found" at runtime.

### Negative

- **Duplication risk if a sibling pipe-decorator wants HSV.** If the
  hypothetical `cowsay`-equivalent or any v2 pipe-decorator also wants
  a rainbow gradient, both projects now own copies of the same 30
  lines. Mitigated by the revisit trigger below.
- **No expression-language pivot.** A future user request like "let
  me supply my own colour function as `-e 'hsv(phase*2)'`" would need
  abaco. anuenue's [pipe-purity ADR](0001-pipe-purity.md) already
  ruled out user-supplied expressions, so this is a non-issue under
  current scope.

### Neutral

- The function lives in `src/hsv.cyr` (extracted at v0.9.0). The M0
  scaffold plan anticipated splitting it out; M1–M5 deferred while
  there was only one consumer (the M5 phase-cache builder, itself in
  `filter.cyr`). At v0.9.0 the fuzz harness's `emit-phase-esc` target
  in `fuzz/emit-phase-esc.fcyr` became the second consumer and the
  split landed. `main.cyr` / `filter.cyr` / `animate.cyr` /
  `tests/anuenue.tcyr` / `tests/anuenue.bcyr` all include `src/hsv.cyr`
  before `src/filter.cyr` since the filter references `ANUENUE_PHASE_MOD`.
- M6 (colour-mode negotiation) added `_rgb_to_256` and `_rgb_to_16`
  quantisation in `src/color.cyr` (`_channel_to_6` + the xterm
  256-cube + the bright-16 palette). These are *adjacent* to
  HSV→RGB but distinct: they consume the RGB output of `hsv_rainbow`
  and quantise it to terminal palettes. They share the
  "small-integer-only math, inline" justification documented here,
  but they're not HSV themselves. No ADR carve-out needed.

## Alternatives considered

- **Depend on `abaco` for HSV→RGB.** Rejected for the cost reasons in
  Consequences. abaco is the right tool when the project needs a
  general expression evaluator; anuenue needs one closed-form integer
  function and never grows beyond it.
- **Depend on Cyrius stdlib's hypothetical `color` module.** The
  stdlib doesn't ship one as of Cyrius 6.0.1. If a future stdlib
  release adds `color::hsv_to_rgb`, that's the right thing to migrate
  to — sandhi-bumping the toolchain rather than the abaco dep. Note
  for future readers: re-evaluate when the stdlib version pinned in
  `cyrius.cyml [package].cyrius` bumps and ships `color`.
- **Split into `src/hsv.cyr` as its own compilation unit.** Shipped
  at v0.9.0 — the M0 scaffold plan's anticipated split finally
  landed once the fuzz harness's `emit-phase-esc` target became the
  second consumer (alongside the M5 phase-cache builder in
  `filter.cyr`). `main.cyr` includes `hsv.cyr` before `filter.cyr`
  so the latter can reference `ANUENUE_PHASE_MOD`.
- **Floating-point HSV (`H` in `[0, 360)`, `S, V` in `[0, 1]`).**
  Rejected. The 6-sector integer form at S=V=1 is exact and matches
  the rainbow brand. Floats would introduce rounding decisions, would
  not be reproducible across hosts, and would require a `f64 → u8`
  cast we'd then have to defend at every audit.

## Revisit triggers (post-v1.0)

Two scenarios should reopen this ADR:

1. **Second pipe-decorator wants HSV.** If a sibling tool (boxes-
   equivalent, cowsay-equivalent, pv-equivalent — whichever ships
   first post-v1.0) wants its own rainbow tint, the inline copy is
   no longer free. Either extract to a shared crate
   (`agnos-hsv-rainbow`? slot in the [shared-crates registry](https://github.com/MacCracken/agnosticos/blob/main/docs/development/planning/shared-crates.md))
   or pull abaco for both.
2. **User-supplied colour expressions become a real ask.** If post-1.0
   we relax the pipe-purity rule on user expressions (which today
   would be a violation of [ADR 0001](0001-pipe-purity.md)), abaco
   becomes the natural carrier.

Neither trigger is active today; this ADR ships in its "inline" form
and waits.
