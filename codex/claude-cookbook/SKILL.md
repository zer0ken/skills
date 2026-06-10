---
name: claude-cookbook
description: Use when the user wants to find an Anthropic Claude cookbook recipe/notebook for a topic, wants best-practice example code from the Claude cookbook, or asks for Claude cookbook examples. With no argument, infer a relevant topic from the conversation and search for matching best-practice recipes. Also handles claude-cookbook update / 업데이트 to self-update.
---

# Claude Cookbook Finder

## Overview

Find relevant recipes in Anthropic's official Claude cookbook by searching the
`anthropics/claude-cookbooks` GitHub repository — the authoritative source.
This skill **finds and lists** matching notebooks; it does not summarize their
contents (the user can ask for that separately if they want it).

Repository only. No WebSearch, no local cache, no clone. Always live, so the
index is never stale.

## When to Use

- The user asks to use Claude cookbook examples, with or without a query.
- The user asks "is there a cookbook for X?", "find a Claude recipe for X",
  "what's the best-practice example for X".

**Two modes:**

| Invocation | What to search for |
|---|---|
| Cookbook request with a query/topic | Use the query/topic directly. |
| Cookbook request with no query | Infer 1–3 relevant topics from the recent conversation (what the user is building or asking about) and search those. State the inferred topic before showing results. |

If the argument is `update` / `업데이트` / `check update`, do NOT search — run the
self-update check in **Source & Updates** instead.

## Procedure

1. **Fetch the index (two live calls, run in parallel):**
   - File list (authoritative, always current — includes notebooks the README may not list yet):
     `https://api.github.com/repos/anthropics/claude-cookbooks/git/trees/main?recursive=1`
     → take every `.ipynb` path.
   - Descriptions & categories (human-readable):
     `https://raw.githubusercontent.com/anthropics/claude-cookbooks/main/README.md`

2. **Determine the query.** If args present, use them. If not, infer from
   conversation context and explicitly tell the user what topic you inferred.

3. **Match & rank.** Match the query against notebook paths/filenames and their
   README descriptions. Pick the most relevant (typically 1–5).

4. **Present results.** For each match:
   - **Title** (from README, or derived from the filename)
   - Category / directory
   - GitHub link: `https://github.com/anthropics/claude-cookbooks/blob/main/<path>`
   - One-line description (from README when available)

   If **no match**: say so plainly and offer the nearest adjacent recipes.

## Output Format

```
Topic: <query or inferred topic>

1. <Title>
   - Category: <dir/category>
   - Link: https://github.com/anthropics/claude-cookbooks/blob/main/<path>
   - Description: <one line>

2. ...
```

End by noting the user can ask for a deeper read of any listed recipe.

## Common Mistakes

- **Relying on README alone for the list.** The README index can lag behind new
  notebooks. The git tree is the authoritative file list — use it for coverage,
  README for descriptions.
- **Fetching the platform page** (`platform.claude.com/cookbook`). It is
  JS-rendered and unreliable to scrape. Use the GitHub repo.
- **Summarizing notebook bodies unprompted.** Scope is find-and-list only.
- **No-arg mode without stating the inferred topic.** Always say what you
  inferred so the user can correct it.

## Source & Updates

This skill is distributed from a git repository, not bundled with any project:

- Repository: https://github.com/zer0ken/skills (file `codex/claude-cookbook/SKILL.md`)
- Installed copy: `~/.codex/skills/claude-cookbook/SKILL.md`

**Install or update (single file, no git or clone needed):**

PowerShell (Windows):
```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/codex/claude-cookbook/install.ps1 | iex
```
Bash (macOS/Linux/WSL):
```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/codex/claude-cookbook/install.sh | bash
```
Re-running the command always fetches the latest version — install and update
are the same command.

**Self-update check** (triggered by `claude-cookbook update`): do NOT search. Instead,
diff the canonical file against the installed copy and report the result.

```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/codex/claude-cookbook/SKILL.md -o /tmp/claude-cookbook-remote.md
diff /tmp/claude-cookbook-remote.md ~/.codex/skills/claude-cookbook/SKILL.md
```
- No diff → tell the user the skill is already up to date.
- Diff present → an update is available. Show the one-line install command above
  and offer to run it. Updating overwrites `~/.codex/skills/claude-cookbook/SKILL.md`,
  so confirm with the user before running it.

If this skill ever misbehaves or returns stale results, run the self-update check
first; then point the user to the repository to report anything still broken.
