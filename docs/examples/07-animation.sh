#!/bin/sh
# 07 — Animation mode.
#
# Surface: -a (alias --animate) enables animation. The filter
# buffers stdin once (64 KB cap), pre-tags grapheme clusters,
# then repaints the buffered frame ~60 times a second (16 ms
# interval) with the phase advanced by -S per frame, for the
# duration window specified by -d.
#
# Flags:
#   -a / --animate         turn animation on
#   -d / --duration <sec>  duration in seconds (0 = until SIGINT)
#   -S / --speed <int>     phase advance per frame (default 1)
#
# Expected: a multi-line input scrolls through the rainbow for
# ~3 seconds; Ctrl-C cleanly restores the cursor.
#
# Note: animation needs a TTY. Without --force-color, an input
# piped to /dev/null or `tee` drops to MONO passthrough.
#
# Cite: src/animate.cyr (anuenue_animate / _render_frame /
# signalfd HUP/INT/TERM handling). ADR: docs/adr/0001-pipe-purity.md
# § Deliberate exceptions (64 KB cap, single-buffer).

set -eu
ANUENUE=${ANUENUE:-anuenue}

cat <<'EOF' | "$ANUENUE" -a -d 3 -S 2
        _    ____ _   _  ___  ____
       / \  / ___| \ | |/ _ \/ ___|
      / _ \| |  _|  \| | | | \___ \
     / ___ \ |_| | |\  | |_| |___) |
    /_/   \_\____|_| \_|\___/|____/

      pipe-decorator family · ānuenue
EOF
