---
name: osiri
description: Peer review protocol for auditing another agent's document, report, or claims. Use when the user invokes /osiri, asks for a peer review, a claim audit, an evidence check, or a reviewer-author round trip over a report carrying benchmark numbers, derived values, figures, or provenance.
metadata:
  author: 오세연
  version: "1.0.0"
  domain: review
  triggers: peer review, osiri, claim audit, evidence class, finding, reviewer, author response, benchmark report, figure consistency, provenance, recheck
  role: guardian
  scope: output
  output-format: guidance
---

# osiri - agent peer review

Peer review protocol shared by 오세연 for review between agents. One agent reviews as the reviewer, another answers as the author, and the file holding the findings is the only shared state.

## Roles and Boundaries

- The reviewer audits claims and records findings. The reviewer does not edit the reviewed document, raw data, figure, generator, or product source.
- The author verifies each finding before changing the source. An accepted finding may require document correction, derived-data or figure regeneration, and provenance updates.
- Do not run benchmarks or change external state during a document review unless the review scope explicitly authorizes it. Record missing evidence and the discriminating check instead.
- Preserve reviewer comments, author responses, and follow-ups. Do not rewrite resolved discussion or use an `OUTDATED` artifact as current evidence.

## Review Setup

Create one `<NN>_peer_review.md` in the runbook. A new-session reviewer must be able to start from this file alone. Record:

- review objective and target documents;
- absolute runbook and product-source paths;
- expected source revision and dirty state;
- authoritative raw data, figure, generator, and provenance locations;
- the only files the reviewer may modify and prohibited actions.

Keep a review index at the top:

```text
| Section | Scope | Priority | State | Last comment | Next actor |
```

Use `TODO`, `IN REVIEW`, `OPEN`, `ANSWERED`, `RECHECK`, `RESOLVED`, and `SKIP`. Update the index whenever a comment or state changes. Review `ANSWERED` and `RECHECK` sections first, then the highest-priority `TODO`; do not reread `RESOLVED` or `SKIP` sections unless their evidence changed.

Choose only applicable review sections. A report with benchmark evidence commonly needs:

1. reported numbers and derived values;
2. experiment contract and fairness;
3. interpretation and causal wording;
4. figure-to-data consistency;
5. document structure and repetition;
6. provenance, links, revision, and checksums.

## Evidence Review

- Decompose a compound statement into atomic claims. Classify each as `Observed`, `Measured`, `Derived`, `Sourced`, `Inferred`, or `Hypothesized`; do not promote one class to another.
- Cite the exact file and field, line, formula input, or canonical publication that supports the claim. A matching summary is not a substitute for authoritative raw evidence.
- Confirm that evidence uses the workload, population, configuration, semantics, version, and comparison unit named by the claim.
- Recompute decision-relevant values. A measured comparison must preserve absolute values, units, baseline, sample count, aggregation, and variability.
- Trace every plotted point and label to final raw data and verify the rendered figure for overlap, clipping, axis units, and caption consistency.
- Separate current, diagnostic, pilot, excluded, and `OUTDATED` evidence. State why a run was adopted or excluded.
- Treat a proposed mechanism as inference until a controlled experiment, counter, trace, or profile tests it. Qualify or remove wording stronger than the evidence.
- Do not create findings for personal style preference. Report a wording or layout issue only when it changes technical meaning, traceability, or readability.

## Incremental Review

- Review one section per pass and open at most five new findings, ordered by impact.
- Read only the artifacts needed for that section. Record the verified scope once; avoid long exploration logs and repeated lists of fields that matched.
- Use `BLOCKER` for an invalid primary result or decision, `MAJOR` for a material claim or reproducibility defect, `MINOR` for a bounded evidence or presentation defect, and `NIT` only for a concrete low-impact correction.
- Assign one disposition: `keep`, `weaken`, `qualify`, `replace evidence`, or `remove`.

Reviewer finding:

```text
### R-A-001 [MAJOR] [OPEN] <failed claim or review outcome>
- Location:
- Claim:
- Evidence class:
- Evidence:
- Finding:
- Requested action:
- Disposition:
```

Author response, appended below the finding:

```text
#### A-A-001 [ANSWERED]
- Response:
- Evidence or decision:
- Applied or proposed change:
- Remaining question:
```

Reviewer follow-up:

```text
#### R-A-001-C [RESOLVED]
- Verification:
- Final disposition:
```

If evidence is still insufficient, use `[RECHECK]` and name the exact discrepancy and required evidence. Never delete or silently revise an earlier comment.

## Resolution and Finalization

- The author accepts, rejects, or narrows a finding with evidence. Agreement alone is not verification.
- After an accepted correction, rerun the smallest derivation, figure build, link check, or checksum verification that can falsify it. Do not rerun an experiment when the raw result is unchanged.
- A finding becomes `RESOLVED` only after the reviewer checks the corrected source and evidence. `ANSWERED` means the author has responded, not that the finding is closed.
- Issue the final verdict after every P0 section is `RESOLVED` or `SKIP`. State the reviewed scope, unresolved limitations, verification status, and whether the report is publishable; do not repeat the discussion history.

## Install and Update

PowerShell (Windows):

```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/claude/osiri/install.ps1 | iex
```

Bash (macOS / Linux / WSL):

```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/osiri/install.sh | bash
```

Re-running the command fetches the latest version; install and update are the same command.
