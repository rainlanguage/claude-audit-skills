#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"

mkdir -p "$SKILLS_DIR"

for skill_dir in "$SCRIPT_DIR"/*/; do
    skill_name="$(basename "$skill_dir")"
    [ -f "$skill_dir/SKILL.md" ] || continue
    ln -sfn "$skill_dir" "$SKILLS_DIR/$skill_name"
    echo "Linked $skill_name"
done
