---
name: cleanup
description: Clean up resources used only by the current session and preserve reusable data outside the project. Use on an explicit cleanup request or as the mandatory workflow finishing step. Other session endings suggest this skill; pi delegates finishing to an orchestrator that has it.
---

# Session cleanup

Execute cleanup when invoked. At an ordinary session ending, suggest using this skill rather than treating the suggestion as authorization to execute it. Workflow finishing requires execution. Address the user in Korean using the neutral technical written-style rule.

## Ownership and preservation

Inventory resources created or allocated by this session from its actual records: temporary files, worktrees, processes, containers, Docker images, and other allocations. Confirm the execution host and any container or SSH boundary. An unfamiliar name or location is not proof of ownership. Include only resources used exclusively by this session; leave shared resources, other sessions' changes or worktrees, user deliverables, reused images, and servers intact. Report uncertain ownership and retained resources with reasons. Never start, stop, restart, or replace a model server without the user's permission for that action.

Decide which data has a concrete reuse purpose before deleting anything. Preserve useful data under `~/agent-assets/<project>/<asset>/`, outside the project. Derive project and asset names from confirmed identity; avoid secrets and personal data without an authorized reuse purpose. Contents have no required format except a lowercase `readme.md` explaining origin, purpose, reuse instructions, and required files. Use a new run or asset name when a destination already contains different data. Do not archive ordinary temporary files merely because they exist.

Verify the preserved files and `readme.md` before removing their source. Record the discoverable absolute path, summary, date, original user request or decision, and validity condition in the executing agent's existing memory mechanism. This is reusable work context, not a new global instruction; do not copy it into every agent's memory. If preservation or memory recording fails, retain the source and report the failure.

Decide context notes one by one, as the `take-a-note` skill defines them and the instructions' `Context notes` rule requires: every note this session wrote under `~/.agents/notes/<session>/`, and, at the finishing of a my-workflow run, the run's `<run root>/notes/`. Preserve a note when it holds context that outlives the session and that the artifacts, commits, PR, or issue do not already carry, such as an open decision, work left for a follow-up, or a finding about the codebase; delete it otherwise. Preserve under `~/agent-assets/<project>/context-notes-<session or run>/` with the `readme.md` above, and list every note in the report with its decision and the reason in one line.

## Execution

State the concrete cleanup targets, retained resources, and assets before executing. This preview adds no recurring approval requirement: proceed within the existing authorization, asking only for actions that already require permission.

For every destructive command, confirm the exact target and exclusive session ownership in the same call as deletion. Use recorded exact paths, saved PIDs, container IDs, and image IDs. Do not use broad prune, wildcard deletion, `pkill`, or process-name matching. Inspect image references before removing a session-built image; retain it if any other resource uses it. Remove a session-created worktree only after preserving necessary changes and files and verifying its root and branch. Do not delete the active checkout or the workflow evidence needed to finish the run.

Make repeated invocations converge: check actual existence, recognize already preserved assets by their contents, and report already removed targets without failing or creating duplicate archives or memory entries. Recheck ownership before acting; an old inventory cannot authorize deleting a replacement resource.

Report what was removed, preserved asset paths, retained resources and reasons, and failures or unverified work. Never claim a planned cleanup ran. For workflow completion, also write the execution evidence required by the current finishing stage. pi does not load this skill; a pi worker hands finishing to its orchestrator instead of bypassing cleanup.
