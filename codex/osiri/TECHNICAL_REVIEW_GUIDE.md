# Technical Review Guide

Updated: 2026-10-19.

Scope: code, design, and pull request reviews, including long-running implementation reviews between two agents ([Long-Running Implementation Review](#long-running-implementation-review)). This file is sufficient for GitHub comments and short review runbooks. Read [TECHNICAL_REPORT_GUIDE.md](TECHNICAL_REPORT_GUIDE.md) only when the review also needs report-level experiment, table, or figure rules.

## Choose the Review Surface

Set the objective, depth, and priorities from the current review request before selecting the form. Do not carry a previous review's special focus into unrelated reviews. When priorities are unspecified, select them from the task and the material risks in the change. Do not force every review into the same template.

- Use a **formal finding review** for a pull request decision, merge requirement, or defect list. Apply the `R` IDs, evidence, and required-outcome rules below.
- Use a **GitHub discussion draft** when the purpose is to classify an issue, compare interpretations, or propose the next engineering decision. Write it as a concise message from one engineer to the team. Do not add finding IDs, severity, a verification report, or a limitations section unless they change the decision.
- Prepare a requested local draft in the review runbook. Posting or updating a GitHub comment requires explicit authorization; a request to draft or compare comments is not authorization to publish. Keep detailed failure matrices, command results, and experiment procedure in a linked runbook only when the team needs them.

## Choose the Explanation Density

Use **concise mode** by default. Open with the decision and a one- or two-sentence system summary. Keep each finding to the failed behavior, evidence needed to establish it, and the requested change. Write a finding's cause, effect, and request as connected prose in that order; do not open with a sentence that restates the title, and do not force every paragraph into a summary-sentence-then-detail pattern. Do not restate or enumerate what the reader can infer, and omit concepts the intended reader already knows.

Use **compact explanatory mode** when an unfamiliar systems concept is necessary to understand a finding, the reader is new to the subsystem, or correctness depends on an ordering across components. Keep the same concise opening and finding table. For the affected finding only, state the system purpose, define the unfamiliar term by an observable condition, walk through the component sequence, and end with the requested change. Stop once the reader can understand and implement the request.

Before using compact explanatory mode, read the applicable repository `AGENTS.md` and `AGENT_GUIDE.md` plus the relevant workspace guide. Use [PERFORMANCE_MEASUREMENT_GUIDE.md](PERFORMANCE_MEASUREMENT_GUIDE.md) for benchmark evidence and [SYSTEM_ANALYSIS_REPORT_GUIDE.md](SYSTEM_ANALYSIS_REPORT_GUIDE.md) when a persisted runbook must connect several system layers. Apply their technical criteria without importing report structure into a GitHub comment.

## Problem Definition and Experimental Evidence

Apply the ordering in this section when the user explicitly asks to prioritize the problem definition, causal explanation, or experimental justification. This is an optional review focus, not a mandatory first pass for every review. An implementation, correctness, or performance review follows its own requested priorities. Read the PR description, relevant issues, and cited evidence to evaluate the stated concern. The request to scrutinize a claim does not establish that the claim is wrong. If the user also limits this pass to high-level review, inspect code only as needed to check the claimed mechanism or parameter meaning.

- When the requested focus is a challenge to the problem definition and the evidence supports an objection, lead with that claim and the correction needed. A request for experiment details supports the objection; it must not replace it with a generic request for more information. If the claim is supported, state that result. Separate a false claim from a claim whose evidence or applicable conditions are incomplete.
- Check the scope supported by each piece of evidence. A result under specific conditions does not by itself establish a broader conclusion or the need for a proposed change. Identify the additional evidence required wherever the conclusion extends beyond the tested conditions.
- Prefer relevant experiments from the same product as the first comparison for a product claim. Read the linked issue or report rather than relying on recollection. Use papers to establish algorithm properties and fill evidence gaps. A shared product name does not establish matching revisions, workloads, or parameter semantics.
- State the conditions that limit a comparison. Results obtained under different conditions may help narrow a broad claim, but do not establish what happens under the original conditions. Explain which conclusion the comparison supports without implying equivalence or superiority.
- Distinguish author-reported results from results independently reconstructed from original data. Missing data in the reviewer's local workspace says nothing about whether a colleague retained it. Identify what the PR links or supplies, and request missing evidence from the author through the draft.
- Keep the first setup request at the level needed to understand the completed experiment: server and software environment; dataset and query selection, ground truth, and metric definition; effective build and search parameters; comparison design and execution method. Request the reproduction method and original results, not only a shell command.
- First ask the author to explain what they ran. Do not assign a comparison with another team's experiment, prescribe a new benchmark campaign, or enumerate a full measurement checklist before examining the existing procedure. Name a specific control or additional test immediately only when it is necessary to resolve the stated claim. Expand warm-up, affinity, repetition, and statistical requirements when the evidence reveals a relevant gap.

For an explicitly requested problem-definition review with a supported objection, use the order: requested correction → relevant evidence and comparison limit → concise setup request → unsupported steps from result to proposed change. Keep the setup inventory in one place. Do not repeat it as findings or append an implementation checklist. A solution recommendation or merge verdict is not required before the problem is established.

## Review Runbook and Published Comments

- Store a PR-specific draft under `<repository>/<quarter>/runbooks/pr<N>/`, unless the user specifies an existing runbook. Keep its evidence in `data/`. Use the reviewer's R&D workspace for review work; do not assume it contains the PR author's experiments.
- When the user edits and publishes a draft, read the actual comment and compare it with the local draft. Identify which changes affect the objection, requested work, or tone. Do not describe unchanged arguments as improvements or infer intent from formatting alone. When the user edits the local draft, keep the edited wording in later rewrites.
- Treat the published comment as the record of what was sent. Keep the local draft distinct unless asked to synchronize it, and do not replace a published comment during a local revision. Distinguish reusable writing preferences from task-specific review priorities. Do not turn a one-off instruction to challenge the problem definition into a default review sequence, or copy incidental wording and experiment-specific values into this guide.

## Formal Review Output Contract

- Start with the decision and a system-level summary. In the document and every finding, explain the expected system behavior and failure before files, symbols, GUCs, or record formats. Include implementation detail only when needed to establish the cause or locate evidence.
- Number findings `R1`, `R2`, and so on, once per PR or issue. Section numbers group the document; finding IDs do not form a hierarchy such as `R1-1`.
- In a follow-up review, an unresolved finding keeps its ID and a new finding continues after the last ID (`R7` after `R1`–`R6`); never restart at `R1`. State each earlier finding's status as `Open`, `Partial`, or `Resolved`.
- State the review decision and its direct reason. Use `Request changes` while a supported path can return wrong results, lose or diverge state, fail recovery or security, or lacks verification required to establish those properties. Name the finding ID that requires another review instead of adding a generic group heading.
- For dead configuration, bounded maintainability, CI, or documentation defects without a demonstrated runtime correctness failure, state the required action in the finding itself.
- Use `Known issue` only for an accepted item outside the current merge scope. Keep its `R` ID for summary traceability, state the next discussion point, and do not present it as a required change or attach a PR line.
- Do not add priority to the ID or summary table.
- Use `ID | 분류 | 핵심 내용` for the summary. `분류` is one concrete area such as `트랜잭션`, `재시작`, `HA`, `테스트`, `설정`, `CI`, or `문서`, not an abstract quality attribute. `핵심 내용` is a short phrase naming the observed failure. Evidence belongs in the finding body.

## Review Method

1. Establish the contract: identify the owner, authoritative state, persistence boundary, observer, supported modes, and mode-specific correctness, recovery, performance, and operational requirements.
2. Trace the failure: state the trigger, state change, missing check or ordering rule, and observable result. Name the result directly, such as wrong rows, primary/standby divergence, failed restart, data loss, latency, throughput, or resource use. Separate confirmed behavior from inferred impact.
3. Review effective and persisted state:
   - Do not treat one configuration command, warning, SQL hook, or operator instruction as enforcement. Treat administrator filesystem access as an operational boundary.
   - Keep requested mode separate from eligibility to enter it. Distinguish stable persisted states from procedures such as quiescing writers or taking a base backup.
   - Persist a protected transition before its first irreversible mutation. Define behavior for write failure and restart during transition. Missing, corrupt, or incompatible state fails closed unless recovery proves safety. Require rebuild, reseed, or validation before replication re-entry when needed.
   - A durable intent record proves only that a transition started, not that it completed. For replacement, state which version remains authoritative before commit, write and fsync the new version before making it current, change the current version only after commit is known, and remove the old version last. Define the recovery decision before and after each boundary.
4. Check system boundaries: a primary-local marker cannot invalidate a disconnected standby; identify replicated invalidation or external fencing. Keep transition work out of the steady-state hot path, select lifetime-fixed modes at startup or handler construction, and verify that inactive modes skip their serialization, WAL, allocation, and sync paths. Support performance claims with measured allocation, copy, I/O, latency, throughput, or resource use.
5. Define complete resolution:
   - Cover applicable create, insert, update, delete, rebuild, drop, commit, abort, retry, restart, configuration reload, disconnect, reconnect, replay, query, and promotion paths. Preserve every supported product mode; disabling one is a fallback, not a complete resolution.
   - State the required outcome before implementation suggestions. Separate merge requirements from optional suggestions, and mark a finding resolved only after proportionate verification.
   - When correctness and performance constrain the same path, state both requirements. Do not prescribe restoring per-operation I/O when recovery can be established at another boundary.
   - Name the smallest tests that cover the failure boundary and supported versions. Do not create a finding for planned pre-release performance evaluation unless the current merge requires a measured pass/fail threshold; mention it at most once under limitations.

## Formal Finding Format

Write each finding in this order:

1. `R<n>: <failed system outcome>`: use a concise phrase without `-합니다`, `-됩니다`, or a final period. Name a specific result, not a topic or vague concern.
2. System behavior: one short paragraph that explains how the failure in the title arises and what the reader observes, without restating the title, using only the implementation detail needed to establish the cause.
3. Required outcome: state the condition the code must preserve and the tests needed for re-review.
4. Code evidence: place it at the end of the finding. Write the code path on one line and the bare GitHub URL on the next line so GitHub renders its code preview. Do not wrap the URL in a Markdown link. Prefer the exact changed PR line; use a commit-pinned `blob/<commit>/...#Lx-Ly` URL when useful. Cite the one location that establishes the failure; add another only when the failure spans two locations.

   ```text
   `src/path.rs#L10-L20`
   https://github.com/<org>/<repo>/blob/<commit>/src/path.rs#L10-L20
   ```

   If evidence is unavailable, mark the required lookup and keep the finding as a draft; never invent or silently omit it.

The four items above define composition order, not output headings. Do not print labels such as `System behavior`, `Code evidence`, or `Required outcome` in the comment.

State conditions directly in prose. Do not create labels such as `C1` or make the reader resolve cross-references.

A reproduction note contains only the relevant environment or version, minimal trigger, expected result, and actual result. Omit exploration history, command transcripts, and report-level procedure.

## GitHub Discussion Draft

For an issue-thread proposal whose failure is sufficiently established, use this compact order. When the user explicitly asks to prioritize a challenge to the problem definition, use the applicable sequence in [Problem Definition and Experimental Evidence](#problem-definition-and-experimental-evidence) instead:

1. State the recommended framing in one sentence. When multiple symptoms have different causes, say that they should be discussed separately.
2. For an item already corrected, name the system behavior, the `main` commit or PR that changed it, and only the remaining confirmation needed before closing it.
3. For the open item, describe the kind of system failure in ordinary Korean before naming internal fields or functions. Recommend one solution first and state the reason it fits the failure.
4. End with the tracking decision requested from the team, such as closing one item, opening a linked issue, or keeping the current issue open.

Keep the thread comment short enough to read without a separate summary. Include only code links that establish the current status or the remaining failure. Do not include shell commands, build output, worktree state, tool history, or a self-review checklist unless the reader must know them to make the decision.

At the discussion level, describe the concept before its representation. For example, write `인덱스 교체 이력을 교체 대상 디렉터리 밖에 기록합니다` before proposing a file name or record fields. Add fields, state-machine names, or ordering details only when the thread is deciding between implementations.

Explain why a failure occurs before describing how the code detects it. First name the system operations whose durable progress can diverge, the state exposed by a crash, and the resulting failure. Then define repository-specific files and fields and show the concrete mismatch. A check such as `GenerationMismatch` is the detection point, not the cause.

## Engineer-to-Engineer Review Comments

Use these rules when asking a colleague to revise a PR, issue, or other engineering record.

- State the review decision and change scope in the opening. Place each requested edit after the concise reason needed to understand it. State the required outcome and, when it helps, how much work is expected, such as `지금 조사할 필요는 없고, 앞으로 할 일로 이슈에 남기면 됩니다`. Include a concrete code revision when the evidence supports one, but leave edits the author can derive, such as replacing a sentence with a link, to the author.
- Match the request ending to its weight: `수정이 필요합니다` or `수정 부탁드립니다` for a required change, `~해주시면 좋겠습니다` for a softer request, and `~하면 됩니다` or `~빼도 됩니다` for an easy follow-up. Do not repeat one ending in every finding, and do not end with nominal labels such as `삭제 대상입니다`, `이번 PR의 수정 범위입니다`, or `논의 대상입니다`; both read as machine-generated. Do not replace repetition with elaborate polite formulas.
- Use at most one deliberate qualifier such as `제가 보기에는` or `...라고 생각합니다` when a judgment needs a cushion. Do not remove an intentional qualifier solely to make the prose more forceful.
- Frame the reason as a shared team practice and recordkeeping consequence. Do not assign motive or carelessness to the author, and refer to `나중에 합류한 팀원` rather than their seniority.
- When several changes are requested, put a short `ID | 항목 | 판단` table after the opening summary. Include only findings so every row carries an ID. Put contextual judgments under the finding they support. In a follow-up review, acknowledge resolved items with one phrase such as `리뷰 반영 확인했습니다` and name only the open ones. Do not list resolved IDs, describe what the reviewer verified, or remark on the reviewer's earlier omissions.
- LLMs may produce a first draft, but repository-visible prose must reflect the author's review of both technical content and language.
- Keep concision separate from evidence loss. Retain the change and verification rationale, scope, limitations, and decision record needed by future team members or their Agents. Request a separate issue only when the out-of-scope item needs follow-up.

## Long-Running Implementation Review

Use this form when an Author agent implements a change over many checkpoints without per-checkpoint commits, a Reviewer agent reads the code and reproduces the checks, and the user makes the design decisions. One review document per project holds the decision record (for example `03_<topic>_code_review.md`). Pull requests cut from that work still follow the formal review rules above.

### Record format

- Author sections report the source snapshot (archive SHA-256 and file manifest), the changed behavior and files, the commands run and their results, an invariant table with evidence or the reason a check was not run, and any decision request.
- Reviewer sections record what was reproduced, the findings, the user's decisions, and the next work unit.
- The document header keeps one status line. Status sentences accumulate; each new section replaces only the final next-owner sentence (`다음 담당`).
- A decision that changes an earlier decision names it in the form `N절 결정 M을 대체한다`. Earlier sections are not edited.
- Record the user's approval with the user's own words, or a close paraphrase, and the date. An approval that was not confirmed in the conversation is recorded as `확인 필요`, not as approved.
- Use one finding-ID scheme per document and continue its numbering across phases. Do not create a new prefix for each phase. Put the grade in brackets after the ID, such as `GQ-4 [L]`, using the [severity mapping](#severity-mapping). Each work unit triages findings by grade, so this form differs from the formal PR rule that omits priority.
- Put each instruction relayed to the Author in one code block. Its first line names the decision section and the review-run directory.
- A decision request to the user gives the context, the problem, the options with the reason each rejected option fails, the recommendation, and the decision needed. It must read without internal IDs; put IDs and code locations in parentheses as evidence. When the options differ in runtime behavior, add a small worked example with numbers.

### Severity mapping

| Long-running review | `systems-code-review` | [PEER_REVIEW_GUIDE.md](PEER_REVIEW_GUIDE.md) | Definition | Handling |
|---|---|---|---|---|
| `H` | `blocking` | `BLOCKER` | A supported path returns a wrong result, fails to terminate or recover, or loses or diverges state | Fix before the next checkpoint is accepted |
| `M` | `high` | `MAJOR` | A reachable correctness defect, a stated design property with no mechanism that produces it, or a material reproducibility defect | Fix within the current work unit |
| `L` | `medium` | `MINOR` | A bounded defect without a demonstrated wrong result on a product path, such as an unenforced contract, a missing check, or a diagnostic gap | Each `L` states its disposition: fixed in the current unit, or recorded in the open-items ledger with the phase that closes it |
| `D` | `low` | `NIT` | A document or record correction with no code behavior change | Fix in the next document update |

Grade a document error by its effect. A wrong statement that formed the basis of a user decision is `M` or `L`, not `D`. A small code correction that the skill would grade `low` is `L` in the long-running record because it changes code behavior.

### Open-items ledger

Keep one `OPEN_ITEMS.md` per project next to the review document. When a decision section defers an item to a later phase, update its ledger row in the same edit. At each phase boundary, check that every `Open` or `Deferred` row names the phase that closes it.

```text
| ID | 내용 | 출처 절 | 담당 단계 | 상태 | 닫은 근거 |
|---|---|---|---|---|---|
| <ID> | <남은 일> | <결정 절> | <단계> | Open/Deferred/Closed | <절·run·test> |
```

### Document lifecycle and citations

- At each phase boundary, apply [DOCUMENT_REORGANIZATION_GUIDE.md](DOCUMENT_REORGANIZATION_GUIDE.md): a current-status document (00) and a history-and-decisions document (01). Move dated correction paragraphs out of design drafts there instead of extending the drafts. A dated paragraph that follows a corrected formula quotes the old formula, so that a reference such as `위 식` cannot point at a different formula.
- Cite line numbers only together with a fixed snapshot, either an archive SHA-256 or a commit. Cite live code by symbol, such as `scheduler::bind`.
- Review runs follow the layout in [STORAGE_GUIDE.md](STORAGE_GUIDE.md#검토-재현-run).
- While the product tree changes without commits, every run keeps a source archive and manifest. At each phase completion, the Reviewer's decision section asks the user whether to commit or tag the product tree. Agents do not commit or tag without that decision.

## Language and Style

- Use formal Korean endings such as `-합니다` and `-됩니다` for explanations, and the request forms in [Engineer-to-Engineer Review Comments](#engineer-to-engineer-review-comments) for edits and evidence requests. Reserve obligation phrasing for explicit requirements or acceptance criteria. Titles and table cells use concise phrases without sentence endings.
- Preserve code symbols, API names, field names, commands, and artifact IDs verbatim. Do not preserve a conceptual English word merely because the implementation uses it. In high-level Korean prose, use the established Korean term when it explains the same concept more directly. Take conceptual wording from the user's own issues, PRs, and comments (for example, an issue's completion criteria), not from the reviewed PR's prose or documents, which may be machine-generated; reuse only their code identifiers. Write product and edition names in full, such as `Enterprise Edition`.
- When behavior comes from inherited or vendored code, name the upstream implementation before inferring design intent. An unchanged upstream behavior does not show that the current team deliberately selected it. If local documentation, tests, or a decision record do not define the behavior, state that directly.
- Use `replay` for PostgreSQL WAL replay. Do not translate it to `재생`.
- Do not hard-wrap prose. Keep each paragraph and list item on one source line and let GitHub wrap it for display. Add line breaks only between structural elements such as paragraphs, list items, code blocks, tables, and bare evidence URLs, and between sentences where a break helps the reader scan a dense paragraph. Do not apply one break pattern to every paragraph.
- Explain the system concept in ordinary language before introducing repository-specific symbols. On first use, define what a repository-specific file, field, or function does in one short sentence. For example, write `VectorOn은 디스크에 저장된 현재 인덱스를 식별하는 관리 파일을 둡니다. 코드에서는 이 파일을 control/0이라고 합니다.` Do not introduce a path or symbol alone and expect the reader to infer its role.
- Prefer `인덱스를 새로 만든 뒤 이전 인덱스의 WAL부터 replay합니다` over `successor generation에서 predecessor DML을 replay합니다`. Add `index_generation` or `validate_replay_target` only when needed to locate the behavior.
- Prefer the concrete operation over an abstract label: `파일과 상위 디렉터리를 fsync하지 않습니다`, not `비영속성이 있습니다`; `상태 파일에 기록하고 fsync해야 합니다`, not `영속화해야 합니다`. State a fixed limit as its value, such as `mmap 연결의 최대 packet size는 1 MiB입니다`, not as what a component can do.
- Reserve `계약` for an API, format, or cross-component obligation with named parties and conditions, and `정책` for a deliberately selected system or operational rule. For an option or local code path, write `옵션의 의미`, `기대 동작`, `조건`, `제한`, or the operation itself.
- Do not use `gate` as a generic prose label. Write `컴파일 조건`, `merge 전에 필요한 수정`, `검증 기준`, or the check's actual operation. Keep `gate` only when it is an exact code symbol or established external term.
- Use `regression` only when a named earlier revision or measurement is the baseline and the same behavior or metric became worse. To describe origin, write `최근 변경으로 생긴 문제` or `기존 구현부터 있던 동작`; without before-and-after evidence, state that the comparison was not performed.
- Use natural Korean engineering collocations. Avoid phrases such as `회귀 시나리오를 고정합니다`, `종료 조건을 확인합니다`, or `failure boundary를 검증합니다`. Write the operation directly: `보고된 절차를 자동 test에 포함합니다`, `같은 문제가 다시 발생하지 않는지 확인합니다`, or `인덱스 교체 전후에 강제 종료하고 재기동 결과를 확인합니다`.
- In a discussion draft, use a direct and collaborative reviewer voice. `두 현상은 원인이 달라 분리해서 보는 것이 좋겠습니다` is appropriate. Headings such as `검토 결과`, `확인된 결과`, `검증과 제한`, and narration of the reviewer's work belong only when the requested deliverable is a formal report.
- In Korean review prose, name the result directly: `실험에서 recall이 저하됐습니다`, `작성자가 보고한 recall 결과입니다`, or `코드는 캐시 적중 여부와 무관하게 요청 수를 셉니다`. Do not use `관측` in Korean review prose or phrases such as `관측을 반박합니다`. Explain the differing conditions and what the result establishes instead. State comparison limits briefly, using the parameter differences that affect the conclusion.
- Do not use metaphors, personification such as `삼킨다`, compressed phrases such as `오류를 행으로 반환한다`, softened verbs such as `오류 사유를 보여 준다`, rhetorical questions, promotional wording, or conversational filler.
- Do not use an em dash. Use a period, colon, comma, or parentheses.
- Replace vague labels such as `unsafe`, `stale state`, `guardrail`, or `issue` with the failed operation or result.
- Keep only the context needed to understand, verify, and fix the finding. Omit mechanism steps the author does not need in order to act, such as how a connection is closed after the failure. Do not repeat evidence in the summary, body, and verification section.

## Delivery Check

- The review focus and output form match the current request. A problem-definition objection is not a required opening for every review. A discussion proposal does not inherit formal finding IDs or report sections.
- The selected explanation mode matches the reader and the finding. Compact explanatory mode defines only the concepts needed to understand and implement the requested change.
- Each finding connects cause, effect, and request without restating its title or following one fixed paragraph pattern. The comment contains no resolved-ID list, reviewer verification note, or remark on the reviewer's own omissions.
- In a formal finding review, IDs, mapping, and summary columns follow the formal output contract, and every finding has a trigger, failure, exact evidence or draft marker, required outcome, and verification.
- In an issue-thread proposal, the reader can identify the established failure, corrected and open items, and recommended action. In a problem-definition review, the reader can identify the disputed claim, relevant evidence, comparison limit, and information needed from the author. Neither requires a separate report to understand the comment.
- Requests are courteous without repeated polite endings. The comment distinguishes reported results, verified facts, and unresolved causes, and preserves the objection without assigning motive or effort to the author.
- Skipped tests, unavailable environments, and unmeasured effects appear once and plainly only when they constrain the decision.
- Prose follows the Korean style rules; titles and tables remain compact.
