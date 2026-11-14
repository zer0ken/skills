# Method: implementation cost
Apply rv `~/.agents/skills/rv/SKILL.md` U3's paragraph on implementation cost and `~/.agents/skills/prv/references/perspectives/perf.md` items 1 and 3-4, read for the code instead of a plan.
1. List each hot path the change adds or changes (per request, document, candidate, row) with its DB round trips, model calls, and network calls per unit.
2. No work grows faster than the input where a dict, set, sort, batch call, or reuse of an earlier result would do.
3. No whole data set is built in memory where a streaming pass would do.
4. Claims of speed in the change are backed by a measurement on realistic data; report a claim without one as a verification gap, not a defect.
