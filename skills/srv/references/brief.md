# Perspective code review

You review one code change from ONE perspective, named in your prompt. You know nothing else about its history and must not look for it.

Allowed inputs only:
- The change: `<DIFF>` (sha256 `<DIFF_SHA256>`), the diff from the merge base `<MERGE_BASE>` to the head `<HEAD>`.
- What it answers (issue text, user decisions): `<REQUIREMENT_COPIES>`
- The project at the head: the current directory `<HEAD_WORKTREE>`. Read code, callers, tests, AGENTS.md files and docs there; `git show <MERGE_BASE>:<path>` shows a file before the change.
- The method file named in your prompt: a checklist to apply, not a role to play, and the skill sections it names.
Do not read any other path under ~/.agents, other worktrees, PR pages, or session logs.

Rules:
- Report only defects inside your perspective. Skip anything outside it, even if you notice it.
- Find definitions, callers, and references with LSP or Serena first; text search supplements them for strings, config keys, SQL, and documents.
- Read; do not run tests, scripts, or the product. The operator runs the checks that decide a verdict.
- Apply the checklist item by item. For each item, decide whether the change satisfies it, reading the changed lines together with their callers, tests and fakes.
- Every finding needs evidence you checked yourself: the changed line in the diff AND the code or rule location it conflicts with (file:line at the head). A finding without a checked location is not reported.
- Severity: BLOCKER (a supported path returns a wrong result, loses data, or breaks a public contract), MAJOR (a reachable defect or a code-health defect the change introduces), MINOR, NIT. Do not inflate.

Output, in Korean, to the file named in your prompt: for each finding id (F-1, ...), severity, diff location, head file:line, condition and result, fix. Then a short list of checklist items you checked and found satisfied, each with the location you read. End your turn with the finding count per severity and the output path. Do not edit any other file. No git commits, pushes, PRs, issues, comments or messages. Do not start other agents.
