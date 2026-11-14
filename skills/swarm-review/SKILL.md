---
name: swarm-review
description: "Swarm review (srv) of a code change: many blind local-model reviewer sessions each apply one perspective built from rv's review items to the diff, one operator session verifies every suggestion against the code, sends narrow follow-up questions to new reviewers for further rounds, and returns one review document. Use when the user calls /srv, /swarm-review, $srv, or $swarm-review, or asks for a swarm review of a PR, branch, or commit range (코드 변경을 여러 리뷰어 세션으로 훑어 리뷰할 때)."
metadata:
  author: hrlee
  version: "0.1.0"
  domain: workflow
  triggers: srv, swarm-review, swarm review, 스웜 리뷰
  dependencies:
    - rv
    - prv
---

# swarm-review (srv)

srv reviews a code change with a swarm. Several reviewer sessions on the self-hosted model each read only the change, what it answers, and the code at the change's head, and each applies one perspective; one operator session verifies every suggestion against the code, digs further with follow-up rounds, and hands one review document to the caller. The user's words (2026-11-15): "이거 /prv 참고해서, /prv와 같은 방법으로 pi 세션 많이 띄워서 코드에 대해 /rv하게 만들어. 그리고 들어오는 제안은 코덱스가 정리하고, 더 자세히 파기 위해 추가로 리뷰를 계속 해서, 결과적으로 하나의 리뷰 문서를 너한테 가져오라고 해. 이 과정을 /swarm-review , 줄여서 /srv라는 스킬로 저장해. 코덱스 세션 띄우는거 말고 그 다음 부분부터".

The skill starts where the operator session starts: the caller opening that session is the caller's step and is outside this skill. srv names no agent for the operator; asked who the operator should be, the user answered (2026-11-15): "이건 특정 에이전트를 위한 스킬이 아니다." The session that runs srv is the operator, whichever agent the caller chose under its own role rules.

## Relation to prv and rv

prv reviews a plan before code exists; srv reviews a code change (a PR, a branch, or a commit range) the same way, with perspectives taken from rv instead of plan checklists. `rv` is one exhaustive adversarial review by one strong reviewer, item by item in consecutive turns with an item ledger; srv is a wide, cheap, blind sweep whose suggestions count only after the operator verifies them. srv does not replace rv: the caller may run srv first and give its review document to an rv review as an earlier review, the way prv runs before the rv design review.

## Concepts

| Name | Definition |
| --- | --- |
| change | The code under review: the diff from the merge base to the head commit |
| head | The commit under review, checked out as a detached worktree that every session reads |
| merge base | `git merge-base <head> <target branch>`; the diff is taken from it, not from the commit the work started on |
| perspective | One review dimension defined by a method file under `references/perspectives/`, made of named rv review items and `-expert` sections; a reviewer reports only defects inside it |
| reviewer | A self-hosted-model session that applies one perspective (round 1) or answers one follow-up question (later rounds), blind to everything but its inputs |
| operator | The session that runs srv: prepares inputs, launches reviewers, verifies and clusters every suggestion, writes follow-up questions, and writes the review document |
| suggestion | One finding a reviewer reports; it is not a defect until the operator verifies it |
| cluster | A group of suggestions the operator judged to describe the same defect, with one verdict: CONFIRMED, PLAUSIBLE, or REJECTED |
| round | One launch of reviewers followed by the operator's verification of their output; round 1 is the perspective sweep, later rounds answer follow-up questions |
| follow-up question | A narrow question the operator writes from a verified round, sent to new reviewers to dig into one place |
| review document | The one Markdown file srv returns to the caller |

## Inputs

1. The head commit and the target branch (or merge base). Create a detached worktree of the head, save `git diff <merge base>...<head>` as `diff.patch` in the review directory, and record its sha256.
2. What the change answers: the issue body and the decisive comments and user decisions, copied into the review directory, so later edits do not change what was reviewed.
3. The perspective method files, by absolute path.

Reviewers get nothing else: no PR body, no PR reviews or replies, no design documents or measurements of the producer, no conversation. The producer's conclusions break the blindness. Earlier reviews of the same change go only to the operator, to mark which clusters are new.

## Perspectives

A perspective groups rv review items (`~/.agents/skills/rv/references/items.md`) and `-expert` sections so that one reviewer covers it in one turn; the swarm, not per-item turns, carries the thoroughness. Asked how pi reviewers should apply rv, the user chose (2026-11-15) "rv 항목을 관점으로": each perspective is a few rv items, a reviewer reviews only its perspective in one turn, and three sessions per perspective plus follow-up rounds supply the depth. rv's item ledger and one-item-per-turn rule belong to rv's own reviewing session, not to srv reviewers.

Run `trace`, `design`, `correctness`, and `tests` on every change; add the others when the diff touches their area.

| Id | File | rv items and sources | When |
| --- | --- | --- | --- |
| trace | `references/perspectives/trace.md` | U0 problem modeling, U3-claims, repository rules | always |
| design | `references/perspectives/design.md` | U2-concepts, U2-structure, U2-quality; `python-expert` Software Design | always |
| correctness | `references/perspectives/correctness.md` | U3-safety, U3-failure, U3-security; `python-expert` 4.4.5 | always |
| tests | `references/perspectives/tests.md` | U3-tests; `python-expert` Software Testing | always |
| layout | `references/perspectives/layout.md` | U1-import, U1-layout, U1-names, U1-leftovers, U1-precedent | modules, files, or names added, moved, or renamed |
| growth | `references/perspectives/growth.md` | U1-size, U1-split, U3-reuse | new units or dependencies |
| db | `references/perspectives/db.md` | U3-db; `sql-expert` DM-Querying, DM-Processing, DM-Internals | queries, schema, storage backends |
| concurrency | `references/perspectives/concurrency.md` | U3 failure and recovery tracing; `parallel-expert` | tasks, workers, locks, retries, recovery |
| llm | `references/perspectives/llm.md` | `llm-expert` structured output, prompt engineering, diagnosis, serving | prompts, model calls, output contracts |
| cost | `references/perspectives/cost.md` | U3-cost; prv perf | hot paths, batch work, model or DB calls per unit |
| docs | `references/perspectives/docs.md` | U3-docs; `sucks` | documents, docstrings, or user-facing text |

A perspective is a checklist, not a persona. The user's words (2026-11-12): "전문 작업에서는 '역할극'이 아니라, 메소돌로지를 적용해야돼." A new perspective is a new method file whose items name their source (an rv item, an `-expert` section, or a repository rule).

## Procedure

1. Prepare the review directory: the head worktree, `diff.patch` with its sha256, the requirement copies, and the review workspace on the head worktree, created and archived exactly as prv's `## Review workspace` section describes, with title `srv <target> <run number>`. Fill `references/brief.md` and check it for unfilled `<...>` before launching.
2. Before loading the model server, check that it answers (`curl -sS -m 5 <server>/v1/models`) and whether another session is measuring on it (an open `run-*` terminal of another session that calls it, as the harness instructions require). When a measurement is running, ask the user whether to launch now and wait for the answer; the answer covers that run only. Asked whether srv should get a standing exception from the harness's measurement check, the user answered (2026-11-15) "앞으로도 확인하고 나한테 물어보도록 해 그럼", which replaced the earlier answer "항상 응답 확인만". Record in the procedure log the server state, the user's answer, and how many sessions were launched at what time, so a measurement on that server can account for the load.
3. Round 1: launch three reviewers per chosen perspective in the review workspace (`create_agent` in Paseo, provider pi on the self-hosted model, thinking high), all at once; the three sessions of a perspective get the same brief and do not see each other's output, and each writes `round-1/<perspective>-<a|b|c>.md`. Self-hosted reviewers are exempt from the four-session cap, which exists for paid-provider cost (the user's words, 2026-11-14: "동시 규칙은 비용문제때문에 있는거야"). Three per perspective is prv's measured default (prv `## Limits`). Do not read the reviewer files while they run.
4. Verify the round by `references/consolidate.md`: open every cited `file:line` at the head, give each suggestion a verdict, cluster, and re-grade severity. Agreement is not evidence: judge a cluster by the code, never by how many sessions raised it.
5. Write follow-up questions by `references/deepen.md` and launch round `k` (k ≥ 2): new reviewers, the same blind inputs, one question each, output `round-<k>/Q<n>-<a|b>.md`. Verify the round as in step 4, merging its suggestions into the existing clusters.
6. Stop when a round adds no new CONFIRMED cluster, or after round 3, whichever comes first.
7. Write the review document `REVIEW.md` in the review directory, in the format of `references/consolidate.md`, and `procedure-log.md` beside it (steps, sessions per round with launch and finish times, server state, blockers and what was changed).
8. Confirm that no session in the review workspace has a running turn, archive the workspace, and remove the head worktree with `git worktree remove`, as prv's review workspace section says.
9. End the operator's turn with the counts of confirmed clusters per severity, the count of new confirmed clusters per round, the precision per round, and the path of `REVIEW.md`, under 4,000 characters. The caller reads `REVIEW.md`; accepting, rejecting, posting, and fixing are the caller's.

The operator edits nothing but the review directory and the head worktree it created: no repository edits, commits, pushes, PR or issue comments, posted reviews, or messages to people. Reviewers do not start other sessions; the brief says so. The operator does not stop or restart a model server.

## Limits

Unmeasured. srv's first run (PR #1415 of graphai-repository/enterprise-memory, 2026-11-15) is the first record; its procedure log fills this section: precision per round and per perspective, new confirmed clusters per round, session counts, wall time, and blockers. Until then the numbers that hold are prv's, measured on plans: agreement among reviewers was not evidence (prv trials 1 and 3), precision was 37.7% to 66.7%, and a third session per perspective still added confirmed clusters.
