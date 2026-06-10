---
name: uv-setup
description: Convert the current project to uv-based dependency management. Install uv → detect and migrate existing pip/poetry/pipenv setups → set up pyproject.toml/uv.lock/.venv → record uv rules in CLAUDE.md and AGENTS.md. Afterward the uv workflow is enforced for this project. Also handles "uv-setup update" / "업데이트" to self-update.
metadata:
  author: hrlee
  version: "1.0.0"
  domain: python-tooling
  triggers: uv, uv-setup, dependency management, pyproject, pip migration, poetry migration, venv, astral uv
  role: setup
  scope: project
  output-format: action
---

# uv-setup

Convert the current project to [uv](https://docs.astral.sh/uv/)-based Python dependency management, then update the rule docs so the uv workflow is enforced in later work.

## Usage

Call it from the project root (or the target project directory). It takes no arguments — it detects the current state and runs only the steps that are needed (idempotent).

If the argument is `update` / `업데이트` / `check update`, do NOT run the setup — run the self-update check in [Source & Updates](#source--updates) instead.

---

## Procedure

### Phase 0: Pre-checks

1. **Confirm the target directory** — verify the CWD is a Python project root. If inside a worktree (`.worktrees/`), confirm with the user whether the main project is the intended target.
2. **Check whether uv is installed**:
   ```powershell
   uv --version
   ```
   - If installed, go to Phase 1.
   - If not, **attempt installation** (in priority order):
     ```powershell
     # 1st: official standalone installer (Windows)
     powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
     # fallback 2nd: winget
     winget install --id=astral-sh.uv -e
     # last resort 3rd: pip
     pip install uv
     ```
   - After installing, verify with `uv --version` in a new shell. If PATH has not refreshed, tell the user to restart the shell.

### Phase 1: Detect the existing dependency state

Inspect the root to determine the current management style.

| File found | Management style | Action |
|-----------|------------------|--------|
| `pyproject.toml` + `[tool.poetry]` | Poetry | migrate |
| `Pipfile` / `Pipfile.lock` | pipenv | migrate |
| `requirements*.txt` | pip / pip-tools | migrate |
| `setup.py` / `setup.cfg` (alone) | setuptools (legacy) | migrate |
| `pyproject.toml` + `[project]` (PEP 621), no uv.lock | standard | uv can use it directly → `uv sync` |
| `pyproject.toml` + `uv.lock` | **already uv** | skip setup, run Phase 3 only |
| nothing | new | `uv init` |
| `environment.yml` (conda) | conda | **cannot auto-migrate** → report to the user and decide together |

Report the detection result and the planned action to the user in one line before proceeding.

### Phase 2: Migration / initialization

3. **Migration (poetry / pipenv / pip / pip-tools)** — use the unified tool:
   ```powershell
   uvx migrate-to-uv --keep-current-data
   ```
   - `migrate-to-uv` auto-detects the management style, converts `pyproject.toml` to PEP 621 `[project]` form, and preserves dev groups and the like. It also runs `uv lock` as part of the conversion.
   - **`--keep-current-data` is required**: without this flag it **auto-deletes the originals** — `requirements.txt`/`Pipfile`/poetry blocks (a violation of the AGENTS.md "do not mutate originals" principle). Always pass the flag to keep the originals.
   - If auto-detection fails, specify it: `uvx migrate-to-uv --keep-current-data --package-manager poetry|pipenv|pip|pip-tools`.

4. **When only requirements.txt exists and there is no pyproject** (fallback when migrate-to-uv cannot handle it):
   ```powershell
   uv init --bare
   uv add -r requirements.txt
   ```

5. **New project**:
   ```powershell
   uv init
   ```

6. **Preserve originals after migration** — the `--keep-current-data` flag above keeps `requirements.txt`/`Pipfile`/poetry blocks (the AGENTS.md "do not mutate originals" principle). Only advise the user to "remove them yourself after verifying the migration".

### Phase 3: Sync the environment and verify

7. **Lock + create the virtual environment**:
   ```powershell
   uv sync
   ```
   Confirm `.venv/` and `uv.lock` are created.
   - If a `No requires-python value found` warning appears, `pyproject.toml` has no `requires-python`. Pin it to the current interpreter with `uv python pin <version>`, or add `requires-python = ">=3.x"` to `pyproject.toml [project]`, then run `uv sync` again.

8. **Verify** — confirm it actually works (no assumptions):
   ```powershell
   uv run python --version
   ```
   If a test runner is present, confirm the environment is healthy with `uv run pytest --collect-only` or similar.

### Phase 4: Update the rule docs

Update **both CLAUDE.md and AGENTS.md** at the project root. Create them if absent.

9. Insert the marker block below. **If the marker already exists, replace the whole block** (avoids duplication). CLAUDE.md/AGENTS.md are context files, so write the block contents in English (language policy):

   ```markdown
   <!-- uv-managed:start -->
   ## Dependency Management (uv)

   This project manages dependencies with [uv](https://docs.astral.sh/uv/). **Do not use `pip`/`poetry`/`pipenv` directly.**

   | Task | Command |
   |------|---------|
   | Add dependency | `uv add <pkg>` |
   | Add dev dependency | `uv add --dev <pkg>` |
   | Remove dependency | `uv remove <pkg>` |
   | Sync environment (install) | `uv sync` |
   | Run a script/command | `uv run <cmd>` (e.g. `uv run python main.py`, `uv run pytest`) |
   | Update lock | `uv lock` |
   | Pin Python version | `uv python pin <version>` |

   **Rules:**
   - Never call `pip install` directly → use `uv add`.
   - Never hand-edit `requirements.txt` → manage dependencies in `pyproject.toml` via `uv`.
   - Do not manually activate the venv → run via `uv run` (it uses `.venv` automatically).
   - Commit `uv.lock`. Do not commit `.venv/`.
   - Setting up a fresh environment is a single `uv sync`.
   <!-- uv-managed:end -->
   ```

10. **Check `.gitignore`** — add `.venv/` if missing. Make sure `uv.lock` is not ignored.

### Phase 5: Report

11. Summarize to the user:
    - which steps ran (install / migration / init)
    - the verification result (`uv run python --version` output)
    - the docs updated (CLAUDE.md, AGENTS.md)
    - user follow-ups (e.g. consider removing the original requirements)

---

## Core principles

### 1. Idempotent — safe to re-run
If it is already a uv project, skip setup and only check/update the rule docs and `.gitignore`. The marker block is always replaced, so it never duplicates.

### 2. Do not mutate originals
After migration, do not auto-delete the existing `requirements.txt`/`Pipfile`/poetry config. Leave verification to the user and only advise removal.

### 3. No assumptions — confirm by verifying
Do not assume "it was installed/migrated". After each step, confirm the actual result with `uv --version`, `uv sync`, `uv run python --version` before moving on.

### 4. conda is not handled automatically
`environment.yml` (conda) environments have different dependency semantics, so do not auto-convert them. On discovery, report to the user and decide the conversion direction together.

---

## Notes

- **When called from a worktree** — inside `.worktrees/`, the rule docs are written only to the worktree copy. If the goal is to apply to the main project, confirm with the user.
- **PATH not refreshed** — after a fresh uv install, if the current shell does not recognize it, advise that a shell restart may be needed.
- **monorepo / workspace** — if there are multiple packages, confirm with the user whether uv's workspace feature (`[tool.uv.workspace]`) is needed.

---

## Source & Updates

Distributed from a git repository, not bundled with any project:

- Repository: https://github.com/zer0ken/skills (folder `codex/uv-setup/`)
- Installed copy: `~/.codex/skills/uv-setup/`

**Install or update (single file, no git or clone needed):**

PowerShell (Windows):
```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/codex/uv-setup/install.ps1 | iex
```
Bash (macOS / Linux / WSL):
```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/codex/uv-setup/install.sh | bash
```
Re-running the command always fetches the latest `SKILL.md` — install and update are the
same command. (The installer refuses to overwrite a symlinked install dir, so a developer
working from a cloned repo is never clobbered.)

**Self-update check** (triggered by `uv-setup update`): do NOT run the setup. Diff the
canonical file against the installed copy and report:

```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/codex/uv-setup/SKILL.md -o /tmp/uv-setup-remote.md
diff /tmp/uv-setup-remote.md "$HOME/.codex/skills/uv-setup/SKILL.md" \
  && echo "up to date" || echo "UPDATE AVAILABLE"
```
- No diff → tell the user the skill is already up to date.
- Diff present → show the one-line install command above and offer to run it. Updating
  overwrites `~/.codex/skills/uv-setup/SKILL.md`, so confirm with the user first.
