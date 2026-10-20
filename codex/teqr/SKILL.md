---
name: teqr
description: Write or revise evidence-based technical reports, runbooks, experiment notes, and test or benchmark plans. Use when the user invokes /teqr or requests these engineering documents. For code, design, and pull request review findings or GitHub discussion comments, use osiri.
metadata:
  version: "1.0.0"
---

# teqr - technical report guide

Read [Technical Report Guide](TECHNICAL_REPORT_GUIDE.md) before writing or revising the requested document. Apply its evidence, terminology, structure, figure, table, and verification rules at the depth needed for the current task. Keep the user's requested format and destination; the guide's example structures do not require unnecessary sections.

## Supporting Guides

The supplied report guide references workspace documents that are not bundled here: `TECHNICAL_RETROSPECTIVE_GUIDE.md`, `SYSTEM_ANALYSIS_REPORT_GUIDE.md`, `REVISION_GUIDE.md`, `references/README.md`, and `references/charts/README.md`. Locate and read applicable resources in the target workspace when needed. Do not invent their contents or copy historical measurements from examples. If a resource is unavailable, continue with the supplied guide and disclose the limitation only when it affects the document or verification.

For code, design, and pull request review policy, use the `osiri` skill and its bundled `TECHNICAL_REVIEW_GUIDE.md` when available. Use this skill for the report-level evidence and presentation rules in a mixed task.

## Scope and Verification

Document existing evidence and distinguish measured results, inference, decisions, and unverified claims. A request to write a report or plan does not authorize running its benchmarks, changing product code, or publishing externally. Run only checks within the authorized task scope, and identify skipped checks and missing evidence without reporting them as passed.

Apply product-specific naming rules only when reporting on the named product. When figures are needed, default to a light theme and readable typography; use interactive visuals when they help exploration, and standalone exportable artifacts for report figures.

## Install and Update

PowerShell (Windows):

```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/codex/teqr/install.ps1 | iex
```

Bash (macOS / Linux / WSL):

```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/codex/teqr/install.sh | bash
```

Re-running the command installs the latest version. Start a new agent session to load it.
