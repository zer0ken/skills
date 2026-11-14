# Verify, cluster, and write the review document

## Verify each round

1. Open every cited file:line at the head yourself. Verdict per suggestion: CONFIRMED (you observed the contradiction, omission, or wrong result in the code), PLAUSIBLE (needs execution or more tracing; write the question that would decide it), REJECTED (cite the line that contradicts it), DUPLICATE-OF <cluster>.
2. Cluster duplicates across sessions and rounds. Agreement among reviewers is not evidence: judge a cluster by the code, not by how many raised it.
3. Re-grade severity yourself by rv's `## Finding schema` severities; the reviewers' severity is not used.
4. When earlier reviews of the same change are given, mark per cluster whether one already raised it.
5. Per round and per reviewer: CONFIRMED, PLAUSIBLE, REJECTED counts and precision = confirmed / (confirmed + rejected). Per round: new CONFIRMED clusters.

## Review document

Write `REVIEW.md` in Korean in rv's `## Result format`, so the caller can use it as it uses an rv review:

1. The verdict paragraph, the index, and the judgment sections of rv's result format, filled from the clusters of the perspectives that cover each section; a section no perspective covered says `미확인: 이 관점을 돌리지 않았다` instead of a judgment.
2. The findings: every CONFIRMED cluster as an rv finding (`R-001 심각도, 근거 구분: 문제. 위치. 조치.`), with the head file:line, the condition and result, and the fix.
3. `## 확인하고 배제한 항목` and `## 검증 범위` as rv says, the latter naming the perspectives and rounds run and what was not run.
4. After rv's sections, the srv appendix:
   1. `## 남은 질문`: PLAUSIBLE clusters, each with the execution or tracing that would decide it.
   2. `## 기각한 제안`: each REJECTED suggestion with the line that contradicts it.
   3. `## 라운드와 리뷰어 수치`: per round, sessions launched, suggestions, CONFIRMED, PLAUSIBLE, REJECTED, new CONFIRMED clusters, and precision; per perspective, the same counts.

Read only the reviewer outputs, the inputs they had, and the repository. Edit nothing else. No git commits, pushes, PRs, issues, comments or messages.
