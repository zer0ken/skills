---
name: openai-cookbook
description: Use when the user invokes /openai-cookbook or wants to find an OpenAI Cookbook example, recipe, notebook, or best-practice sample for OpenAI APIs, models, tools, or SDK usage. With no argument, infer a relevant topic from the conversation and search matching official OpenAI Cookbook examples.
---

# OpenAI Cookbook Finder

## Overview

Find relevant examples in OpenAI's official Cookbook by searching the
`openai/openai-cookbook` GitHub repository.

This skill finds and lists matching notebooks or markdown examples; it does not
summarize their contents unless the user asks for a deeper read.

Repository only. No WebSearch, no local cache, no clone. Always live, so the
index is never stale.

## When to Use

- The user runs `/openai-cookbook` with or without a query.
- The user asks for an OpenAI Cookbook example, OpenAI API recipe, SDK sample,
  model usage example, embeddings/RAG example, evals example, tool-calling
  example, or similar best-practice sample.

**Two modes:**

| Invocation | What to search for |
|---|---|
| `/openai-cookbook <query>` or a topic is given | Use the query/topic directly. |
| `/openai-cookbook` with no query | Infer 1-3 relevant topics from the recent conversation and search those. State the inferred topic before showing results. |

If the argument is `update` / `업데이트` / `check update`, do NOT search. Run the
self-update check in **Source & Updates** instead.

## Procedure

1. **Fetch the index (two live calls, run in parallel):**
   - File list:
     `https://api.github.com/repos/openai/openai-cookbook/git/trees/main?recursive=1`
     -> include `.ipynb` and `.md` paths except root housekeeping files such as
     `README.md`, `CONTRIBUTING.md`, and `LICENSE.md`.
   - Repository README:
     `https://raw.githubusercontent.com/openai/openai-cookbook/main/README.md`

2. **Determine the query.** If args present, use them. If not, infer from
   conversation context and explicitly tell the user what topic you inferred.

3. **Match & rank.** Match the query against paths, filenames, headings, and
   README descriptions where available. Pick the most relevant examples,
   typically 1-5.

4. **Present results.** For each match:
   - **Title** from README or path
   - Category / directory
   - GitHub link: `https://github.com/openai/openai-cookbook/blob/main/<path>`
   - One-line reason it matches

   If there is no direct match, say so plainly and offer the nearest adjacent
   examples.

## Output Format

```
Topic: <query or inferred topic>

1. <Title>
   - Category: <dir/category>
   - Link: https://github.com/openai/openai-cookbook/blob/main/<path>
   - Why it matches: <one line>

2. ...
```

End by noting the user can ask for a deeper read of any listed example.

## Common Mistakes

- **Confusing OpenAI Cookbook with Claude Cookbook.** For Anthropic Claude
  examples, use `claude-cookbook` instead.
- **Relying only on README.** Use the git tree for coverage and README for
  descriptions.
- **Summarizing example bodies unprompted.** Scope is find-and-list only.
- **No-arg mode without stating the inferred topic.** Always say what you
  inferred so the user can correct it.

## Source & Updates

This skill is distributed from a git repository, not bundled with any project:

- Repository: https://github.com/zer0ken/skills (file `claude/openai-cookbook/SKILL.md`)
- Installed copy: `~/.claude/skills/openai-cookbook/SKILL.md`

**Install or update (single file, no git or clone needed):**

PowerShell (Windows):
```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/claude/openai-cookbook/install.ps1 | iex
```
Bash (macOS/Linux/WSL):
```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/openai-cookbook/install.sh | bash
```
Re-running the command always fetches the latest version.

**Self-update check** (triggered by `/openai-cookbook update`): do NOT search.
Diff the canonical file against the installed copy and report the result.

```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/openai-cookbook/SKILL.md -o /tmp/openai-cookbook-remote.md
diff /tmp/openai-cookbook-remote.md ~/.claude/skills/openai-cookbook/SKILL.md
```
- No diff -> tell the user the skill is already up to date.
- Diff present -> an update is available. Show the one-line install command
  above and offer to run it.
