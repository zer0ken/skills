# Verify, cluster, and write the review document

## Verify each round

1. Take the suggestions from each output body by their ids (F-1, ...); a reviewer's reported totals are not used.
2. Open every cited file:line at the head yourself. Verdict per suggestion: CONFIRMED (you observed the contradiction, omission, or wrong result in the code), PLAUSIBLE (needs execution or more tracing; write the question that would decide it), REJECTED (cite the line that contradicts it), DUPLICATE-OF <cluster>.
3. When reading cannot decide a suggestion and a direct check is cheap, run a small script in the review directory that calls the head's own functions with the project's environment, and keep the script and its log. Such a run is evidence for one verdict, not a test pass; the repository's test suite, CI, real models, and databases stay unrun unless the caller's approval covers them.
4. Cluster duplicates across sessions and rounds. Agreement among reviewers is not evidence: judge a cluster by the code, not by how many raised it. A duplicate that independently found a confirmed cause counts as CONFIRMED in precision but adds no cluster.
5. Re-grade severity yourself by rv's `## Finding schema` severities; the reviewers' severity is not used.
6. When earlier reviews of the same change are given, mark per cluster whether one already raised it.
7. Per round, per perspective, and per reviewer: suggestions, CONFIRMED, PLAUSIBLE, REJECTED, and precision = confirmed / (confirmed + rejected). Per round: new CONFIRMED clusters.

## Review document

Write `REVIEW.md` in Korean, so the caller can read the top section alone and use the rest as it uses an rv review:

1. `## 확정 결함` first: rv's verdict paragraph (verdict, head and merge base as commit links, cluster counts per severity), then a table of every CONFIRMED cluster: id `R-nnn`, severity, head file:line as a link pinned to the head, condition and result, and fix.
2. `## 추가 확인이 필요한 질문`: PLAUSIBLE clusters, each with the execution or tracing that would decide it.
3. `## 기각한 제안`: each REJECTED suggestion with the line that contradicts it.
4. `## 라운드와 리뷰어 수치`: the numbers of step 7 of the verification, with the definition of precision.
5. rv's judgment sections of `## Result format`, filled from the clusters of the perspectives that cover each section; a section no perspective covered says `미확인: 이 관점을 돌리지 않았다` instead of a judgment. Then one section per review area with its findings, `## 확인하고 배제한 항목`, and `## 검증 범위` last, naming the perspectives and rounds run, the scripts run, and what was not run.

Read only the reviewer outputs, the inputs they had, and the repository. Edit nothing else. No git commits, pushes, PRs, issues, comments or messages.
