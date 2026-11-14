---
name: pr
description: "Open a PR, take it through the CI gate, and finish it through merging. Write the title as a noun phrase, and write the body as an issue reference line at the very top followed by a short `-` bullet summary of about three bullets (10 lines or fewer including sub-bullets), with the detailed explanation placed at the bottom of the body. Always apply the sucks skill to Korean prose. Use when the user calls /pr or instructs to open a PR (PR 을 올리라고 지시할 때), when merging or finishing a PR (PR 을 병합하거나 마무리할 때), when stacking PRs with the GitHub stacked PR feature (PR 을 스택하라고 지시할 때), and when CI fails on code that was just pushed or merged (방금 push 하거나 병합한 코드의 CI 가 실패했을 때)."
metadata:
  author: hrlee
  version: "1.20.0"
  domain: workflow
  triggers: PR, pull request, PR 스택, stacked PR, gh stack, PR 올려, PR 생성, gh pr create, PR 병합, CI 실패
  role: guardian
  scope: output
  output-format: action
---

# PR

The author rereads the relevant global rules and project rules and confirms the scope of application.

## Prerequisite

Call `sucks` first with the Skill tool. Apply its rules to all Korean prose in the body.

## Branch and history

The author names a PR branch in the form `{prefix}/[issue-number-]goal-of-the-PR`. If there is no issue, omit the number and the following hyphen, and keep the goal short. The forms are `fix/1208-resume-recovery` and `refactor/ingestion-pipeline`.

The author makes local commits freely but pushes only the PR branch to the remote, and does not push a worktree's temporary branch. Tidy the remote history into the minimum number of meaningful commits worth tracking. History that was already pushed is also updated with `--force-with-lease` when necessary, and when rewriting history, check that the SHAs of commits owned by other PRs or main do not change (filter-branch discards signatures, so narrow the range with `--ancestry-path`).

The author synchronizes approved draft PR work to the remote branch and body each time a unit is completed, and tidies the history before the final review. With every push, fit the summary and deployment impact, the verification, and the remaining scope to that commit. Rewrite the body as the current proposal each time instead of appending a section per event such as a rebase, a measurement, or a review round; the body describes the change to be merged, and its history stays in the commits and the review replies. When the specified conditions for switching to ready are met, switch immediately. Creating, pushing, merging, and deleting a PR are performed only within the approved scope.

The author links read-only settings and data into the PR worktree with symlinks and copies any mutable DB. The virtual environment and node_modules are installed independently, and the author does not affect other work through changes to shared dependencies. Before removing a PR worktree, check that no process is running from that worktree's build outputs. A running process makes the directory removal fail with `Device or resource busy`, so terminate only the processes the author started, by PID, and then remove. A link made to shared material, like a Windows junction, is released first before removal. Follow the repository's verification and commit conventions, and record the verification that was run in the commit body.

## CI gate and document updates

Before reporting a change as complete, or before committing, pushing, or merging, the author runs locally, with the same commands, every check that CI runs. The list of checks is not a remembered list but the set of commands run by the repository's CI configuration file or by the build target that CI calls. If only part of it is run or the options are changed, a check that passed locally fails in CI. Use the options attached to the CI commands as they are, such as an option that treats warnings as failures, and run the cheaper checks first.

A check that CI does not run is not that repository's gate. If a formatter or linter already fails on the unchanged default branch, the tool has no configuration file, and no CI job runs the tool, the author does not fix that failure and does not require it of the worker. In this case, check only that the new code follows the format of the surrounding code and adds no new warning.

A check that targets the whole repository can fail only locally because of untracked files. The CI checkout does not have those files, so if the failure occurs only in untracked files, the author cleans up the temporary files left in the working tree with `git status` and re-checks against the committed tree.

If a change alters behavior described in a document, the author fixes that document to the same behavior as the code before requesting review or merging, and includes it in the same commit. The targets are the documents the repository maintains, such as the README, `docs/`, design decision records, and per-module `AGENTS.md`. A PR that contradicts its own documents even though every check passes is a design regression. The document states the current behavior as fact and does not write the before-and-after history of the change. If the behavior described in a document did not change, omit the update and write that judgment in the details of the PR body.

## PR state and verification

A PR proceeds in the order draft, ready, review verification and fixes, merge. Draft is the in-progress state, and ready is the state in which the finalized change is reviewed. Requesting review from a person puts the PR up for review, so if it is a draft, first change it to ready and then assign the reviewer, and do not assign only a reviewer while leaving it as a draft, nor pass `--draft` and `--reviewer` together. When the user instructs a request for a person's review, that instruction is the instruction to switch to ready regardless of the work stage, and the merge timing does not change. A ready PR that becomes unreviewable because of a redesign or large rework goes back to draft at once with `gh pr ready --undo`, and its review requests are withdrawn; a comment asking the reviewer to wait for a new head does not replace this. When it is reviewable again, mark it ready and request the review again. Removing a requested reviewer through REST `DELETE pulls/{n}/requested_reviewers` failed with 422 when the PR had a bot reviewer, and GraphQL `requestReviews(userIds: [], union: false)` removed them (observed 2026-11-13). In the review stage, concentrate on resolving review defects, and reconsider the new design only when a finding requires it. Verification and fixes are performed against the current head.

Before switching to ready or requesting review, the author reads the entire `git diff <base>...HEAD` directly and corrects debug code, changes unrelated to the purpose, and missing files. Most of these traces are caught when the author reads the diff, and if left, the reviewer spends time on the traces instead of on defects. For size and reuse, apply rv's `크기와 증가` judgment to one's own change in the same way.

Before reporting the PR state or numbers in the body, the author verifies at the head the PR points to. The working worktree's HEAD can be ahead of the PR head because of unpushed commits another session left on the same branch, so check the difference with `git log origin/<branch>..HEAD`, and if there is a difference, check out the PR head into a detached temporary worktree, verify, and then remove it. The test pass count is also not carried over from a worker's report but confirmed from the CI log of the same head. The last number of the job URL that `gh pr checks <number>` gives is the job ID, so read the count per shard with `gh run view --job <ID> --log | grep -E '[0-9]+ (passed|failed)' | tail -2`, write the isolated-environment figures that are the basis of the judgment in the body, and mark the host pytest values as reference values. If the repository runner has no path or `-k` argument passing so that the per-path isolated figures cannot be reproduced locally, do not leave irreproducible figures in the body and substitute the CI shard total.

After posting, the author checks CI and resolves failures. When a failure appears, run the same check on the base to tell whether it is a failure that already existed, and show with that result that this change added no new failure. If a dependent PR exists, follow the stacked PRs section. Check the actual repository settings and the user's instructions for the merge method. Use a squash or rebase merge only when the user or the repository decided on that method. When merge commits are allowed and there is no separate instruction, use `gh pr merge --merge`. When `--subject` is specified for a squash, include the PR number `(#N)` in the title directly.

Before merging, the author confirms with `gh pr checks` that all the required checks of the official CI passed. A worker's report and checks run only partly locally are not grounds for merging. The administrator bypass (`--admin`) is used, following the instruction, only when the user first instructed to use it. Approval to merge or starting my-workflow is not this instruction. The user's words (2026-11-10): "사용자에가 먼저 그렇게 하라고 지시한 경우 사용자 지시에 따라." If there is no such instruction and branch protection requires an approval that the token cannot give by itself, report that the PR is left open and waiting for that approval. Merging, deleting a remote branch, and dismissing a review are performed only within an explicitly approved scope.

After creation, the author checks `closingIssuesReferences` again. The success output of the merge command is not grounds that the merge is complete, so after the merge confirm the merge commit with `gh pr view <number> --json state,mergedAt,mergeCommit` and also look up the actual issue state. If the automatic closing failed, close it within the approved scope together with the PR and SHA, and if it goes beyond the approved scope, report the remaining state. Do not treat the work as complete by narrowing the scope needed to close the core issue or by splitting that scope into a separate issue.

The author uses honorific speech (존댓말) in the Korean body to be posted and explains with reasons, measurements, and sources instead of the user's name. Distinguish a proposal before the merge from a confirmed user decision. Refer to a review by date and time (KST) and target SHA, like "10-28 15:30 리뷰(대상 [`e61006b`](commit link))", where the target is a commit link whose text is the 7-character short SHA and the 40-character SHA does not appear in the prose, and do not use a model or agent name, an internal file name, or a round suffix letter. Write GitHub prose with one line per paragraph. If a local check exists, check the current commit and body before posting and confirm the actual result after posting. The check target is not only the body but also the commit messages and the added lines of the diff (comments and docstrings), and if the checker reports only some of the findings, repeat until it reaches 0 locally and then push. Follow `references/anti-slop-preflight.md` for the procedure and for how to rewrite commit messages. Do not add traces of AI use.

For diagrams in a large PR, follow `visuals`. Do not use a raw image URL of a private repository without verifying it on screen. If an attachment is needed, deliver the PNG and confirm the posted result with the GitHub attachment URL generated in a logged-in browser.

## Stacked PRs

A stacked PR is a PR registered in a GitHub stack, the GitHub feature generally available since 2026-10-06 (https://github.blog/changelog/2026-10-06-stacked-pull-requests-generally-available/): a chain of PRs in one repository whose bottom PR targets the trunk and whose every other PR targets the head branch of the PR below it (https://docs.github.com/en/pull-requests/get-started/about-stacked-prs). An instruction such as "PR 스택", "스택해", or "깃허브에서 스택으로" means registering the PRs in this feature. Setting each base to the branch below only lines the PRs up; the docs say GitHub then "shows a **recommendation banner** offering to turn them into a stack", so the base change alone does not finish the instruction. The user's words (2026-11-15): "깃허브 스택은 stacked pr 기능이고 별도의 기능이야."

1. Register with the `gh stack` extension of GitHub CLI (`gh extension install github/gh-stack`). Existing PRs are linked bottom to top with `gh stack link [--base <trunk>] <bottom PR> <next PR> ...`, which "does not create or modify any local tracking state" and corrects bases that do not match the chain; a numeric first argument that names an existing stack appends to it (https://docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands). New stacks built from local branches use `gh stack init`, `gh stack add`, and `gh stack submit`. Read `gh stack <command> --help` of the installed version before calling it.
2. Confirm registration from the API, not from the command's success output: `gh api -H "X-GitHub-Api-Version: 2026-03-10" repos/<owner>/<repo>/pulls/<number> -q .stack` returns the stack number, the PR's `position`, and the stack `size`, and `null` means the PR is not in a stack. Check every PR of the stack and report the stack number.
3. Merge requirements come from the bottom PR's base branch and apply to every PR in the stack. PRs merge bottom up, and merging a PR also merges every PR below it ("Merge the entire stack at once by merging the top pull request. Every pull request below it comes with it."), so a merge waits until the review loop has ended for that PR and for every PR below it. `gh stack merge <stack or PR number>` merges up to the PR named as one all-or-nothing operation; through the REST API, use the asynchronous merge endpoint for stacks. The docs state "You cannot bypass merge requirements when you merge stacked pull requests.", so `--admin` does not apply to a stack.
4. While a PR's base is not the default branch, GitHub does not compute closing references, so even if `Closes #N` is written, it is normal for `closingIssuesReferences` to be empty. Do not treat it as an omission and fix it; look it up again after the base has changed to the default branch, and directly check the state of the linked issue right after the merge and close it within the approved scope.

## Responding to review

After creating the PR or switching it to ready, the author checks CI, detects reviews for at most one hour with the available notification or scheduling feature, and responds within the approved scope. Progress notices and anti-slop results are not counted as reviews. Follow the repository's review procedure, and after a fix, get a recheck from a new reviewer. If the verification of a particular model family cannot be obtained because the reviewer provider's usage limit is exhausted, substitute the remaining provider, but state in the PR body and the final report which family's verification is missing, and decide with the user whether to recheck after that family becomes available. A finding for which only a reply was written is not counted as resolved, and the author does not resolve the reviewer's thread on their behalf.

The form of a response follows the form and place of the writing being answered. To a formal review with finding IDs and severities, answer in the response form of the repository's review procedure (`A-001` and so on). To an opinion, question, or discussion a colleague wrote in prose, answer in prose as if speaking to the colleague. For each finding, write in one paragraph what was accepted and how it was changed and the reason, and for a finding not accepted, its grounds, and refer to a finding by topic, not by ID. Do not attach a response ID, an acceptance marker, a grounds category, or a `file:line` (`파일:줄`) list, and link the needed commits and documents within the sentence. The notice of the fix result left in that place is also written in the same prose. The user's words (2026-11-12): "깃허브 코멘트는 상황을 잘 봐서 작성해라... 지금 사람들이 논의하는 자리니까 방금처럼 코드 리뷰에 대한 응답 포멧을 사용하면 안되는 상황이었다." This is the same as the criterion by which osiri `TECHNICAL_REVIEW_GUIDE.md` separates a formal finding review from a GitHub discussion draft.

Deliver the responses to one review round together, in one review submitted once, so the reviewer gets one notification and reads every answer in one place. Open a pending review on the PR (REST "Create a review for a pull request" with `event` left blank; the GitHub docs: "To create a pending review for a pull request, leave the event parameter blank."), add each thread reply to it with GraphQL `addPullRequestReviewThreadReply`, whose `pullRequestReviewId` is "The Node ID of the pending review to which the reply will belong" (the `node_id` of the REST response), and submit it once with `event: COMMENT`. Write the round's summary, such as the pushed fix commits, findings not accepted, and the re-review request, only in that review's body, and answer there too, one paragraph per finding, the findings that have no thread, such as findings written in a review's body or a PR-level comment. Replying through the REST endpoint for a single thread reply does not join a pending review: each such reply was observed on 2026-11-13 to carry its own `pull_request_review_id`, a separate empty review. Do not post thread replies one by one, do not add a separate PR comment for the same round, and do not submit a review with an empty body. The user's words (2026-11-13), on replies posted as ten thread replies plus a PR comment: "야. 누가 리뷰 응답을 저따구로 코멘트 나눠서 하래? 장난해?"

Only when there is no new finding and the resolution of the existing findings has been rechecked, the author asks whether to merge after the final report. The report explains, to a reader who has not read the conversation, the earlier symptom and cause, the behavior before and after the change, the deployment impact, the verification that was run and the scope not run, and what is left to decide. A merge approval already received is not requested again for the same scope.

## Unattended merge and release

Even when the user entrusts a recurring run with the merge and release of the PRs that run opened, the review is not skipped and another agent takes it. The reviewer is of a different model family from the implementer and receives only the PR number and the base commit, not the orchestrator's conclusion. Before merging, the author posts the reviewer's verdict and the reviewed commit as a PR comment, and this comment also refers to the review by date and time and target SHA. Entrusting the merge to a recurring run is not an administrator bypass instruction, so if branch protection requires an approval that the run's token cannot give, report that the PR is left open and waiting for that approval.

A release proceeds only when all of the following conditions are met.

- A product code change was merged in this run
- There is no open PR
- There is no tag for the target version
- There is no release run on the same day

The author raises the patch version in the manifest and updates only the named package in the lockfile. Replacing the version string across the whole lockfile in bulk also changes the versions required by dependencies. After that, go through the CI gate, PR, review, and merge, run the release workflow, and confirm that the tag, the `latest` release, the deployment artifacts, and the `--version` output of the executable show the same version.

## Metadata

Before creating, look up the repository rules and the actual choices on GitHub. Check `.github/PULL_REQUEST_TEMPLATE*`, `CONTRIBUTING`, the repository's `AGENTS.md`, the issue to link, and recent PRs of the same kind, and confirm valid values with `gh label list`, `gh api`, `gh project list`, `gh project field-list`, and so on.

Choose labels each time after looking up the full list and descriptions. If the list is paginated, check through the last page. Judge not only the change target but also the change type, and keep the exclusivity conditions in the label descriptions. Do not choose from a previous PR's labels or from memory alone.

Make all of the items below into an internal checklist and judge each as `값` (a value), `해당 없음` (not applicable), or `사용자 확인 필요` (user confirmation needed).

- Labels
- Assignee
- Reviewer
- Milestone
- Whether to include in a Project
- The editable fields of the Project
- Whether it is a draft
- Base and head branches
- Linked issues and closing keywords

Use evidence in this order: an explicit request, repository rules, the linked issue, recent PRs of the same kind. Use the linked issue's values only when the repository's PR rules make the PR inherit them. Distinguish Assignee from Reviewer, and do not choose oneself as Reviewer. If the value to apply is not uniquely determined, ask the user before creating. Exclude computed fields and read-only fields from editing. For an issue being worked on, check the assignee the moment work starts, the moment the issue is linked to the PR, or the moment it is newly added to the work scope, and add the user's account with `gh issue edit <number> --add-assignee <user account>` without removing the existing assignee.

Values that `gh pr create` supports, `--label`, `--assignee`, `--reviewer`, `--milestone`, `--project`, `--draft`, `--base`, and `--head`, are passed together at creation. Set Project fields by adding the PR to the Project and then running `gh project item-edit` with the item ID from the `gh project item-list` result and the field ID from the `gh project field-list` result. Choose the actual arguments from the `--help` of the installed `gh` version.

Right after creation, reread the general metadata and the linked issues with `gh pr view --json url,body,labels,assignees,reviewRequests,milestone,projectItems,isDraft,baseRefName,headRefName,closingIssuesReferences`, and the Project fields with `gh project item-list`. A `Refs` reference is not included in `closingIssuesReferences`, so also compare against the body. Compare the pre-creation checklist with the actual values, correct any omission immediately, and look it up again. Do not silently drop a value that could not be set because of missing permission or `project` scope; report which item remains.

## Reader

The reader is a developer who works together in this repository. Write in the vocabulary they know and include only the minimum context needed to understand. Use domain knowledge and technical terms that already exist in this repository as they are, without explaining them. Respect the project's own rules (CONTRIBUTING, README, the repository's AGENTS.md, the existing issue and PR formats) above all. If a project rule and this skill's instructions conflict, follow the project rule.

The reader is not the user, not the user's agent, and not the session that is writing. A fellow developer who has not seen this conversation or the work record reads only the PR title and body and understands it. Do not use names that only the author, the user, or the agent session knows. Examples are the output file names of an experiment run, evaluation set labels (like `A 6,211쌍`), configuration labels (like `route-1500`), ledger seq, session ids, internal file names, and round names. Every proper noun, abbreviation, named number, metric, threshold, and method in the body must satisfy one of two conditions. One is that it already exists where a fellow developer can see it (the code and documents of this repository, a linked issue, a linked public source). The other is that the body explains it in plain words and states its source. The sentence above that says not to explain domain terms that already exist in this repository applies only to names that satisfy this condition.

Write in the order of title, issue reference, summary, and details, and finish with the pre-posting check.

## Title

The title is the name of the behavior that changes when this PR is merged. Write it as a noun phrase whose last word is a noun. Do not put in a sentence-final ending (`~다`, `~습니다`), a nominalizing ending (`~함`, `~음`, `~하기`), or punctuation.

Do not carry the commit title over as the PR title. If the repository's commit convention is a sentence, the commit title is a sentence, and a PR title carried over as it is also becomes a sentence. The `--fill` family of arguments of `gh pr create` fills the PR title from the commit title, so do not use them and pass a noun phrase with `--title`. The same applies to a PR with only one commit.

When turning a sentence into a noun phrase, keep the object and change the predicate into the noun of that action.

| Sentence | Noun phrase |
| --- | --- |
| `LightRAG 질의 경로에 BM25 키워드 검색을 붙인다` | `LightRAG 질의 경로의 BM25 키워드 검색 추가` |
| `빈 응답에서 파서가 실패하는 문제를 수정함` | `빈 응답의 파서 실패 수정` |
| `fix(#12): 재시도 간격이 음수가 되지 않게 한다` | `fix(#12): 재시도 간격의 음수 방지` |

If the repository requires a prefix such as `fix(#12):` or a suffix such as `(#12)`, keep that format and write the rest as a noun phrase. A title that ends in only `관련 수정`, `개선`, or `정리` cannot be distinguished from other PRs, so put in the name of the target that changes. Do not translate code identifiers.

## Issue reference

Check for each PR whether a corresponding issue exists. First check the numbers left in the branch name and commit messages, and if there are none, find an issue that matches the change with `gh issue list`. If there is no corresponding issue, do not put in a reference line, and do not invent a nonexistent number.

If you found an issue, put the reference line at the very top of the body, leave a blank line, and then write the summary. The reader confirms from the first line of the body which issue this PR resolves. Decide the keyword by whether the issue may be closed after this PR is merged.

- `Closes #12` : This PR resolves the core problem of the issue. GitHub closes the issue at merge time.
- `Refs #12` : It handles only part of the issue, or the issue is a parent tracking issue, or it is linked only as background. The issue stays open.

Link the core issue this PR was made to resolve with `Closes`. If every issue to link is `Refs`, check again whether the core issue was left out. If the core problem was resolved, use `Closes` even if side items remain, and write the remaining items in the remaining work of the details.

The reference lines are at most two. Write `Closes` on the first line and `Refs` on the next, and omit the line for a keyword that does not apply. For `Refs`, write the keyword only once and join the numbers with commas. For `Closes`, GitHub closes only the one number right after the keyword, so repeat the keyword for each issue and join them with periods.

## Summary

The summary describes what was changed and why it was changed. An issue link, a list of files and functions, implementation steps, and test results cannot replace this description. Connect the behavior that was impossible or wrong before with the behavior that this PR makes possible or corrects, and write it so that a reader who has not read the conversation record or the diff learns how the system behaves differently from now after the merge. If the core behavior is abstract, explain before and after with one representative request or usage situation.

Write the summary as about three `-` bullets. The count follows the number of changes, and is not increased or reduced to fill three.

1. Write only one thing in one bullet. Do not string unrelated content together in one sentence.
2. Keep sentences short. If more explanation is needed, do not lengthen the sentence; add sub-bullets (indented two spaces). A sub-bullet is also one short sentence.
3. The whole summary, including sub-bullets, does not exceed 10 lines. If it does, move the less important sub-bullets to the details.
4. Do not put a `#` heading line, bold text, or a checkbox (`- [ ]`) in the summary. The body describes the change to be merged and does not track progress.

```
Closes #12. Closes #15.
Refs #1111, #1112.

- LightRAG 질의 경로에 BM25 키워드 검색을 붙인다
  - 인덱스는 첫 질의 때 만든다
  - 벡터 검색 결과와 RRF 로 합친다
- 검색 응답에 키워드 점수를 더한다
```

## Details

Put all the description not included in the summary at the bottom of the body: background, design rationale, verification method, the scope not resolved, and remaining work. Leave a blank line after the summary and continue writing, and do not split it into comments but put all of it in the single body. Only the issue reference and the summary are not folded; fold each section of the details with a `<details>` tag and write the section name as a noun phrase in the `<summary>`, wrapped in an `<h3>` tag as `<summary><h3>섹션 이름</h3></summary>` so the folded section shows at heading size. Markdown heading syntax (`## 제목`) inside `<summary>` does not render and stays literal, so use the `<h3>` tag, not `<h2>`, whose margins are large. Never write a detail section as a bare Markdown heading (`## 제목`) outside `<details>`; every detail section is folded.

Write the content inside each `<details>` in HTML, not Markdown: paragraphs as `<p>`, lists as `<ol>`/`<ul>`/`<li>`, bold as `<b>`, inline code as `<code>`, code blocks as `<pre><code>`, links as `<a href>`, and tables as `<table>`. GitHub renders Markdown inside `<details>` only when a blank line follows `</summary>`, and inside an HTML block Markdown syntax (backticks, `[text](url)`, `- ` items, table pipes) is not interpreted, so mixing the two leaves parts literal. Do not mix: inside `<details>` use HTML tags only and put no Markdown syntax. The issue reference line and the `-` bullet summary at the top of the body stay Markdown.

Divide a large change by feature group, and for each group contrast the existing behavior with the behavior after the change. Do not translate code identifiers such as function and class names.

```
<details>
<summary><h3>기존 대비 변경 사항</h3></summary>
<ol>
<li>카탈로그 도입과 설정 필수화
<ul>
<li>기존: 카탈로그를 선택하는 설정이 없었고 등록 명령으로 넣었다.</li>
<li>변경: 설정이 유일한 등록 경로가 되고, 설정이 없으면 시작이 실패한다.</li>
</ul></li>
<li>삭제 동작
<ul>
<li>기존: 채워진 타입의 삭제가 거부됐다.</li>
<li>변경: 삭제는 엔티티를 <code>null</code> type 으로 변환하고 id 접두사를 유지한다.</li>
</ul></li>
</ol>
</details>

<details>
<summary><h3>배경과 범위</h3></summary>
<p>문서 추가만 포함한다. 제품 코드와 시험은 변경하지 않는다.</p>
</details>
```

## Pre-posting check

Read only the title and body and check the following. If any one is off, write it again.

1. The last word of the title is a noun, and the title is not the same sentence as the commit title.
2. The body alone can answer what problem or need existed before. The answer does not stop at code identifiers or test figures.
3. The body alone can answer how the behavior of the user or the system differs when this PR is applied.
4. There is no AI signature, no Generated with phrase, and no agent session URL.
5. List every proper noun, abbreviation, and named number, metric, threshold, and method in the body, and look each one up with `git grep` in this repository and in the bodies of the linked issues. For a name that is not found, explain it in plain words in the body and state its source, or replace it with the explained wording. If you cannot tell whether a name is one I attached in this work or one a fellow developer can see, treat it as a name I attached.
6. `scripts/check_pr_body.py` of this skill reports no violation for the exact file passed to `--body-file`: `python3 -I ~/.agents/skills/pr/scripts/check_pr_body.py body.md`. It checks the reference lines, the summary of at most 10 lines, and that everything after the summary is a `<details>` section written in HTML, so a bare `## 제목` section or Markdown inside `<details>` fails it. Run it again before every `gh pr create` and `gh pr edit --body-file`.

```bash
gh pr create --title "<명사구 제목>" --body-file body.md
```

Pass the body as a file. An inline string breaks across multiple lines. After posting, reread the title with `gh pr view --json title` to confirm, and if it is a sentence, fix it with `gh pr edit --title`.
