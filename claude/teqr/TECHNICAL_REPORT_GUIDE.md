# Technical Report Guide

Updated: 2026-09-22.

Scope: applies to technical reports, runbooks, reviews, and test plans. Use [TECHNICAL_REVIEW_GUIDE.md](TECHNICAL_REVIEW_GUIDE.md) for code, design, and pull request review policy.

## Guide Selection

- Use this guide alone for focused runbooks, test plans, experiment notes, and reports
  that answer one bounded question without reconstructing a broader system argument.
- Use [TECHNICAL_RETROSPECTIVE_GUIDE.md](TECHNICAL_RETROSPECTIVE_GUIDE.md) for
  engineering retrospectives, especially when an AI Agent changed an implementation,
  experiment contract, heuristic, or interpretation during system R&D.
- Also use [SYSTEM_ANALYSIS_REPORT_GUIDE.md](SYSTEM_ANALYSIS_REPORT_GUIDE.md) when a
  report combines a reference method, current implementation behavior, experimental
  evidence, and a product or engineering decision; compares systems whose parameter
  or metric semantics may differ; or must establish a causal explanation across
  several system layers.
- Do not select the system-analysis profile merely because a document is long.
  Select it when the decision depends on preserving the relationship among mechanism,
  implementation, measurement, and evidence boundary.

## Principles

1. Conclusion first
   - Start with the conclusion, impact, and recommended action.
   - Put supporting analysis after the decision-relevant summary.

2. Make each document independently readable
   - The reader should understand the objective, system context, scope, and key terms without reading the previous report or chat history.
   - Do not start a document with phrases such as "다음 prototype", "이번 변경", "앞서 본 결과", or a case number alone. First state the system problem and why the document exists.
   - Case numbers, experiment names, and internal profile names are evidence identifiers, not the main context. Explain the benchmark or experiment role before naming `Case 109`, `Case 110`, or a profile.
   - Define important terms on first use, especially internal metrics such as `rows_pct`, `cover@N`, `N_push`, `N_check`, `stage ms/q`, `result bound`, or runtime suffixes.
   - If the document depends on another document, summarize the dependency in one or two sentences and link the source. Do not require the reader to infer the missing context.

3. Establish the general model before the specific implementation
   - Assume technical proficiency, but do not assume prior familiarity with the specific algorithm, index structure, storage format, or internal codebase.
   - Introduce the system purpose, general abstraction, execution model, principal parameters, and correctness boundary before repository-specific types, traits, files, or patches.
   - Distinguish properties of the general method from product-specific design decisions. State explicitly where the implementation preserves, narrows, or extends the general method.
   - Express this perspective through the document structure and definitions. Do not add meta commentary about the intended reader or the reader's expected expertise.

4. Report facts, not thought process
   - Do not keep discussion history, expression changes, or author reasoning in the final document.
   - Avoid phrases such as "검토해보니", "생각해보면", "가능성이 있어 보인다", "보는 편이 맞다".
   - Remove traces of interactive discussion, including phrases such as "우리 문제", "현재 논의", "위에서 말한", "사용자가 지적한", or text that explains why wording was changed.

5. Separate facts, inference, and decisions
   - Facts: observed code behavior, benchmark results, test results, config values.
   - Inference: explicitly label it as inference and attach the evidence.
   - Decisions: state the chosen action and expected outcome.

6. Use precise and conventional technical terms
   - Prefer exact terminology and collocations established in the relevant research literature, product documentation, or engineering practice, such as `parameter`, `runtime quantity`, `hot path`, `invariant`, `throughput`, `latency`, and `error rate`. A word can be grammatically valid yet still be non-idiomatic or too generic for the intended technical meaning.
   - Distinguish semantic categories. Use `parameter` for an algorithm or system input, `metric` for a measured evaluation value, and `identifier` or `ordinal` for identity or position. Use `quantity` only for a genuinely measurable numerical magnitude; do not use it as a catch-all label for a mixed list of parameters, metrics, and identifiers.
   - Make table titles and column headings match their data categories. If a table combines parameters and identifiers, name both categories or split the table instead of assigning one broad label.
   - Prefer established compound terms over literal translations or newly coined combinations. For example, use `model training`, `on-disk format`, and `create/open path` when those are the actual concepts; avoid forms such as `model train`, a vague `physical contract` for a file layout, or an unexplained `cold dispatch`.
   - Describe workloads by the operations or measured conditions that define them. Prefer `insert/delete-heavy workload`, `read-heavy workload`, or a stated operation ratio over a nonstandard label whose meaning the reader must infer.
   - Preserve code symbols, API names, persisted artifact names, and machine-readable identifiers verbatim, but do not treat their spelling as the default prose terminology. Introduce the conventional domain term and then map it to the implementation name.
   - If no established term exists, define the chosen term on first use, state its exact scope, and use it consistently.
   - Name the measured condition directly. Do not hide it behind broad labels such as `guardrail`, `caveat`, `signal`, or `row completeness` when the concrete metric is available, and do not substitute generic English meta labels such as `target`, `interpretation`, or `hypothesis` for a concrete metric or established section name.
   - Example: write "`rows_pct < 100%` means the query did not return all requested top-k rows" instead of "row completeness caveat". Write "Recall dropped by 12pp" instead of "quality guardrail failed".

7. Keep scope explicit
   - State what the document covers and what it does not cover.
   - Move out-of-scope items to follow-up work instead of mixing them into the main argument.

8. Tie claims to evidence
   - Performance claims need workload, config, date, and metric.
   - Correctness claims need code path, test, or invariant.
   - Risk claims need the affected path and failure mode.
   - Analysis should identify the system component, measured quantity, and causal link. Do not stop at high-level labels such as "bottleneck", "trade-off", or "path issue" without the metric that supports the claim.

9. Name sections by the technical object
   - Section titles should describe the system component, experiment variable, or decision being analyzed.
   - Avoid generic or meta titles such as "Two Axes", "Structural Probe", "Key Takeaways", or "Discussion".
   - Prefer titles such as "`ef_search` and quantized scoring", "HNSW bottom-layer candidate processing", or "IVF retained candidate limit".

10. Use figures and charts as evidence
   - Use the [visual reference index](references/README.md) to select an example. [PRTC and Scalability](references/charts/README.md) provide chart colors, legends and numeric-label placement; the slide examples cover setup and result layouts. Reuse presentation choices, not historical measurements or claims.
   - Use charts, rather than a large result table, for the main quantitative comparison. Use one chart for one system question and split panels when independent variables would obscure the conclusion.
   - For ANN comparisons, use the `Recall@K`-QPS trade-off as the primary product-comparison chart. Treat Search width-QPS and Search width-Recall charts as parameter-response diagnostics, and identify the Search width of each trade-off point.
   - Number every diagram and chart as `Figure N`, refer to it by number, and explain the axes, comparison, observation, and conclusion in the body text. Keep explanatory paragraphs and boxes out of the chart itself.
   - Use human-readable axis titles with exact units, not source-code variable names. Prefer `Search width`, `QPS`, `Recall@10 (%)`, and `Time (s)` to names such as `ef_search`, `queries/s`, or `index_build_s`.
   - Point labels should contain the directly measured numeric value without repeating the axis unit on every point. When labels are dense, label only decision-relevant points such as the default, endpoints, or frontier points; retain every value in the raw artifact.
   - Use typography that remains readable at the final document size. Resolve label-label, label-marker, label-legend, and label-axis collisions, and verify the rendered SVG or PNG for overlap and clipping before delivery.
   - Name the chart by the measured subject. For comparisons, use `<dataset> <subject> Comparison (#clients=N)` when concurrency applies; avoid presentation titles and inconsistent suffixes.
   - Show the full relevant sweep when the trend matters. Mark a missing configuration as `n/a` or explain why it was not measured.
   - Assign colors by series meaning and keep them stable across related figures. Pair color with marker or line style, and do not put incidental implementation flags such as `SIMD` in a series label unless that flag is the comparison variable.
   - Define necessary short labels before the figure. Do not rely on unexplained suffixes such as `w100`, `r4`, `b8`, `early`, or `rough`.
   - Explain the measured mechanism in prose rather than highlighting only the best point. If the mechanism is not proven, name the unresolved variable and the measurement required to verify it.
   - Use a format supported by the review surface. When Markdown cannot render the source format, retain the source and reproduction command, render SVG or PNG, and reference the rendered asset.

11. Use tables only when they clarify decisions
   - Number every table as `Table N` in document order.
   - Refer to tables by number in the text when a claim depends on the table.
   - Tables should compare targets, expected results, risks, or verification methods.
   - Keep one comparison basis per table. If a table mixes "vs plain" and "vs previous runtime", split it into separate tables.
   - Remove columns that encode a narrow or misleading viewpoint.

12. Use pseudo code to explain system methods
   - Number pseudo code blocks as `Algorithm N` when they define a method or execution path.
   - Explain the algorithm in prose before or after the block by grouping line ranges into system components.
   - Tie each line group to the metric or invariant it is meant to explain.
   - When analyzing existing code, add a mapping from algorithm steps to implementation functions or modules.
   - Keep pseudo code at the method level. Do not include incidental implementation details unless they affect correctness, performance, or the decision.

13. Include expected results
   - Test plans must include expected outcomes.
   - Performance plans should define the primary metric and any required correctness, quality, latency, or named-baseline comparison criteria.
   - Example: a throughput benchmark may also limit the decrease allowed from a named earlier revision or measurement.

14. Record limitations plainly
   - List skipped tests, environment blockers, or measurement limits briefly.
   - Do not turn limitations into long explanations or excuses.

15. Minimize repetition
    - Explain a concept once.
    - In summary documents, link to detailed analysis instead of repeating it.

16. Preserve system-analysis flow
    - Decompose the measured cost by component, then state which explanations the measurements exclude.
    - Present experimental evidence as a system argument: define the mechanism being tested, show the measured trend, explain why the trend follows or does not follow from the mechanism, then state what remains unresolved.
    - If the root cause is not yet proven, stop at unresolved variables and required evidence.
    - Do not introduce a proposal, prototype, or tuning knob as the next step until the document shows why that action follows from the evidence.

17. Optimize evidence density, not detail density
    - Each section should advance the system model, establish a comparison contract,
      support a claim, bound an inference, or determine an action. Remove detail that
      does none of these.
    - Do not obtain density by compressing unrelated claims into one paragraph. Keep
      the causal chain readable and place the evidence near the claim it supports.
    - Repeated numbers are justified only when they serve a different decision role,
      such as summary, comparison, and verification. Otherwise link or refer to the
      authoritative table.
    - For multi-layer analysis, use the authoring artifacts and audit passes in
      [SYSTEM_ANALYSIS_REPORT_GUIDE.md](SYSTEM_ANALYSIS_REPORT_GUIDE.md) to keep this
      density stable across authors and models.

## Style Rules

- Before delivery, audit every sentence that supports a conclusion:
  - Name the technical object or operation.
  - Name the observed behavior or measured result. For a quantitative claim,
    name the exact statistic and comparison basis, or cite the numbered table or
    figure containing them.
  - State the applicable scope and any missing measurement directly.
- In mixed Korean-English prose, preserve implementation identifiers and metric
  names, but write relationships, changes, and conclusions as idiomatic Korean
  sentences. Do not use unresolved English or mixed-language noun chains as
  substitutes for concrete technical terms.
- Rewrite any decision-relevant noun that cannot be mapped to code, raw data, a
  formula, a numbered evidence item, or an explicit condition.
- Apply this audit before writing the final prose. It does not require output labels
  such as `Observation:` or `Decision:`.
- Product naming in charts: use `AkasicDB` as the externally visible product name.
  Do not label a product data series as `VectorOn`; write
  `AkasicDB current`, `AkasicDB baseline`, or the appropriate AkasicDB configuration.
  Use `VectorOn` only when the text or diagram specifically refers to AkasicDB's
  internal vector engine, implementation module, code path, configuration key, or
  artifact identifier. At the first such use, identify the relationship explicitly,
  for example as `AkasicDB's VectorOn vector engine`. Internal filenames, schema
  fields, and machine-readable system keys may retain `vectoron` when renaming would
  break reproducibility.
- Prefer concise paragraphs over long narrative.
- Prefer stable, verifiable wording: `passes`, `fails`, `requires re-measurement`, `not covered`, `not affected`.
- Use `regression` only when a named earlier revision or measurement is the baseline and the same behavior or metric became worse. To describe origin, write `최근 변경으로 생긴 문제` or `기존 구현부터 있던 동작`. If the before-and-after comparison was not performed, say so directly.
- Avoid template residue: do not leave headings like `Decision:`, `Observation:`, `Implication:`, or `How to read:` when a coherent paragraph would be clearer.
- Keep exact engineering terms in English; use Korean only where it improves readability without weakening technical precision.

## Minimum Structure

For most reports:

```text
1. Summary: conclusion, system context, and why the document exists
2. Scope: included/excluded work, required prior context, and key terms
3. Findings or Design
4. Impact / Expected Result
5. Verification
6. Limitations / Follow-up
```

For test or benchmark plans:

```text
1. Objective: system question being answered
2. Workload and Parameters: dataset, query source, index/runtime parameters
3. Metrics: definitions, units, and thresholds
4. Expected Results
5. Execution Steps
6. Limitations
```

## Revision Before Delivery

After drafting or editing, apply [REVISION_GUIDE.md](REVISION_GUIDE.md) to the
sentences and paragraphs before final delivery. Perform numerical, link and
rendering checks separately from prose review.
