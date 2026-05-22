#!/bin/sh
# Version bump script — single source of truth for all anuenue
# version references. Mirrors cyim's pattern (same drift-prevention
# motivation: a v1.2.2 cyim shipped with `--version` reporting 1.2.1
# because the literal was hand-edited in main.cyr — this script
# regenerates the literal unconditionally so it can never drift
# against VERSION).
#
# Usage:
#   sh scripts/version-bump.sh 0.3.0           # bump VERSION + regenerate
#   sh scripts/version-bump.sh "$(cat VERSION)" # regenerate without bumping
#
# Wired side-effects:
#   - VERSION                  (truth — overwritten with $NEW)
#   - src/version_str.cyr      (literal — regenerated every invocation)
#   - CHANGELOG.md             (new `## [$NEW] — DATE` header inserted
#                               after [Unreleased] iff $NEW != $OLD)
#
# Side-effects NOT wired:
#   - docs/development/state.md  (Version row — narrative; manual)
#   - cyrius.cyml `[package].version` (already resolves via
#                                       `${file:VERSION}`)
#   - cyrius.cyml `[package].cyrius` toolchain pin (separate axis)

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <version>"
    echo "Current: $(cat VERSION)"
    exit 1
fi

NEW="$1"
OLD=$(cat VERSION | tr -d '[:space:]')

# 1. Regenerate src/version_str.cyr unconditionally — including
#    same-version invocations. This file is the single source of
#    truth for the anuenue `-V` / `--version` byte sequence; if it
#    drifts vs `VERSION`, `anuenue --version` reports stale data.
#    Same-version `version-bump.sh "$(cat VERSION)"` is the
#    documented "regenerate without bumping" path used by CI.
LEN_ANUENUE=$((${#NEW} + 9))   # "anuenue " + version + "\n"
cat > src/version_str.cyr <<EOF
# src/version_str.cyr — AUTO-GENERATED from \`VERSION\` by
# \`scripts/version-bump.sh\`. Do NOT edit by hand; the next bump
# will overwrite. To regenerate without bumping, run:
#
#   sh scripts/version-bump.sh "\$(cat VERSION)"
#
# Why this file exists: the cyim 1.2.2 toolchain bump shipped with
# \`print_version\` still emitting "cyim 1.2.1" because the literal
# was hardcoded into \`src/main.cyr\` and the version-sync checklist
# didn't list it. Centralising the strings here means version-
# bump.sh writes ONE file every time and \`src/main.cyr\` references
# these vars — no regex hunting, no drift, no fourth-file gotcha.
# Same pattern cyrius + cyim + chakshu + every AGNOS first-party
# tool with a \`--version\` flag uses.

var _VERSION_STR_ANUENUE = "anuenue $NEW\n";
var _VERSION_LEN_ANUENUE = $LEN_ANUENUE;
EOF

if [ "$NEW" = "$OLD" ]; then
    echo "Already at $OLD (regenerated src/version_str.cyr)"
    exit 0
fi

# 2. VERSION file (source of truth). cyrius.cyml resolves
#    `${file:VERSION}` so it doesn't need its own touch.
echo "$NEW" > VERSION

# 3. CHANGELOG.md — insert new version header after [Unreleased].
#    Anchored regex matches ONLY the literal `## [Unreleased]` header
#    line, not body text quoting it.
if ! grep -q "## \[$NEW\]" CHANGELOG.md 2>/dev/null; then
    sed -i "/^## \[Unreleased\]$/a\\
\\
## [$NEW] — $(date +%Y-%m-%d)" CHANGELOG.md 2>/dev/null || true
fi

echo "$OLD -> $NEW"
echo ""
echo "Updated:"
echo "  VERSION"
echo "  src/version_str.cyr (regenerated)"
echo "  CHANGELOG.md (new header inserted)"
echo ""
echo "Still manual:"
echo "  - CHANGELOG.md body (Added / Changed / Fixed sections)"
echo "  - docs/development/state.md (Version row + narrative)"
echo "  - Cyrius toolchain pin in cyrius.cyml [package].cyrius (separate axis)"
