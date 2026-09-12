#!/usr/bin/env bash
#
# Vendor the agent skills in agents/skills into a repo checkout, as tracked
# project skills under <repo>/.claude/skills/<name>.
#
# Why vendor rather than link: cloud sandboxes — Claude Code cloud sessions,
# Cursor Cloud Agents — clone the repo and see none of this machine's home
# directory. Claude Code's docs say user skills do not carry over and belong in
# the repo's .claude/ instead; Cursor reads .claude/skills/ as a compatibility
# path. One tracked copy serves both.
#
# Usage:  bash install/agent-skills.sh <checkout-dir> [skill-name ...]
#         (default: every skill under agents/skills)
#
# Re-runnable: each named skill is replaced wholesale with the current copy, and
# its frontmatter gains a `metadata:` block recording the source path and the
# dotfiles commit — the same shape as the vendored gh-stack skill in spellbook.
# Re-run after a dotfiles change, then commit the result in the target repo.
# Only the skills named here are touched; anything else under .claude/skills/
# is left alone.
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: $0 <checkout-dir> [skill-name ...]" >&2
    exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/agents/skills"
TARGET="$(cd "$1" && pwd)"
shift
COMMIT="$(git -C "$REPO_ROOT" rev-parse --short=12 HEAD)"
SOURCE_URL="https://github.com/Evalir/dotfiles"

if [ $# -gt 0 ]; then
    names=("$@")
else
    names=()
    for d in "$SRC"/*/; do names+=("$(basename "$d")"); done
fi

echo "Vendoring agent skills from dotfiles@$COMMIT into $TARGET/.claude/skills"
for name in "${names[@]}"; do
    src="$SRC/$name"
    dst="$TARGET/.claude/skills/$name"
    if [ ! -f "$src/SKILL.md" ]; then
        printf '  MISSING  %s (no such skill in agents/skills)\n' "$name"
        continue
    fi
    rm -rf "$dst"
    mkdir -p "$dst"
    cp -R "$src/." "$dst/"
    # Provenance goes into the frontmatter, just before its closing fence.
    awk -v url="$SOURCE_URL" -v path="agents/skills/$name" -v commit="$COMMIT" '
        /^---$/ {
            fence++
            if (fence == 2) {
                print "metadata:"
                print "    source-repo: " url
                print "    source-path: " path
                print "    source-commit: " commit
            }
        }
        { print }
    ' "$src/SKILL.md" > "$dst/SKILL.md"
    printf '  vendored %s\n' "$dst"
done
echo
echo "Review and commit in the target:  git -C \"$TARGET\" status .claude/skills"
