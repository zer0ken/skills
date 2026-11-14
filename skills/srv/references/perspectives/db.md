# Method: queries, schema, and storage
Apply rv `~/.agents/skills/rv/SKILL.md` U3 `### DB schema and usage` and the sections DM-Querying, DM-Processing, and DM-Internals of `~/.agents/skills/sql-expert/SKILL.md`.
1. Each added or changed query: its rows, the fewest conditions that produce them, and the index or structure each access direction uses.
2. No query per item in a loop where one set query would do; no filtering, aggregation, or sorting in application code that the DB could do.
3. Every reader and writer of a stored unit whose meaning changed (across backends, tests, and fakes) is updated; search the repository and report one the change misses.
4. NULLs, duplicates, empty sets, and the repository's visibility rules give correct results; transaction boundaries leave no half-done state another session can see.
5. A schema change is listed for human review with its compatibility, migration, and rollback risk.
