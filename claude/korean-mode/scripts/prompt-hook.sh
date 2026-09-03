#!/usr/bin/env bash
# UserPromptSubmit hook. Claude Code adds plain stdout of this event as context for the turn,
# so printing RULES.md is enough to enforce korean-mode on every prompt.
cat "$(dirname "$0")/../RULES.md"
exit 0
