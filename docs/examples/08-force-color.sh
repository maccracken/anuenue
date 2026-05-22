#!/bin/sh
# 08 — --force-color: keep colour across a non-TTY pipe.
#
# Surface: --force-color overrides the "stdout is not a TTY → MONO"
# branch of the colour-mode chain. Useful when capturing rainbow
# output to a file or piping to `less -R`.
#
# Priority: --force-color sits below explicit --color and
# --no-color (those win), but above the auto stdout-not-TTY drop.
# So `--force-color` + a pipe to `tee` keeps SGR escapes intact.
#
# Expected: motd.ansi contains escape sequences (not plain text);
# `less -R motd.ansi` displays the rainbow.
#
# Cite: src/color.cyr (anuenue_detect_color_mode — force_color
# branch). docs/guides/integrating-anuenue.md § TTY detection.

set -eu
ANUENUE=${ANUENUE:-anuenue}

OUT=$(mktemp -t anuenue-motd.XXXXXX.ansi)
trap 'rm -f "$OUT"' EXIT

echo "AGNOS rainbow captured" | "$ANUENUE" --force-color -s 100 > "$OUT"

# Verify the captured file actually contains escapes (would be empty
# of \x1b if --force-color hadn't taken effect):
if grep -q $'\x1b' "$OUT"; then
    echo "✓ --force-color preserved SGR escapes across the pipe"
else
    echo "✗ output has no escape bytes — --force-color did nothing?" >&2
    exit 1
fi

# Render it back with less -R (interactive) — uncomment to view:
#   less -R "$OUT"

# Display the raw bytes safely:
cat -v "$OUT" | head -1
