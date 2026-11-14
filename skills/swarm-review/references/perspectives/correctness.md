# Method: correctness, failure paths, and security
Apply rv `~/.agents/skills/rv/SKILL.md` U3 steps 1-4 and its paragraphs on failure paths and security, and section 4.4.5 of `~/.agents/skills/python-expert/SKILL.md`.
1. Name the one fact the change is safe because of, and check it at its file:line; trace each input from entry through state ownership, write, failure, and recovery.
2. Boundary inputs (empty, None, duplicates, maximum size, unexpected types or enum values) give a defined result on every changed path.
3. Consumers a symbol search misses (serialized fields, DB columns, wire formats, config keys, flags) still read what the change writes.
4. Every failure the change adds or touches reaches a caller or a log with input, target, and cause; nothing swallows a failure or replaces it with a default.
5. Untrusted input (users, files, models, other services) is validated before logic; queries, commands, and paths are built with parameters, never string concatenation.
