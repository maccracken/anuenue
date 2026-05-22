#!/bin/sh
# 04 — MOTD pipeline composition.
#
# Surface: anuenue as the *last* stage of an MOTD chain. The
# producer (iam / bnrmr / agnoshi-motd / etc) emits plain UTF-8
# text; anuenue tints. anuenue must be last because most banner /
# boxes tools don't handle pre-injected SGR escapes.
#
# Expected: a rainbow-tinted banner.
#
# Cite: docs/guides/integrating-anuenue.md § Composing into MOTD
# pipelines. ADR: docs/adr/0001-pipe-purity.md.

set -eu
ANUENUE=${ANUENUE:-anuenue}

# Pattern A — direct compose.
# If iam isn't installed, fall back to a synthetic banner so the
# example still runs.
if command -v iam >/dev/null 2>&1; then
    iam | "$ANUENUE" -p 5
else
    printf 'macro@archaemenid\n  shell: agnoshi\n  AGNOS v0.x\n' | "$ANUENUE" -p 5
fi

# Pattern B — let the user opt in via env var.
# Default to passthrough cat; user exports RAINBOW=anuenue to enable.
banner='AGNOS userland · pipe-decorator family · ānuenue'
echo "$banner" | "${RAINBOW:-cat}"
