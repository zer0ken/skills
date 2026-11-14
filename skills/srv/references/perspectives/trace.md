# Method: requirement-change traceability
Apply rv `~/.agents/skills/rv/SKILL.md`: U0's problem-modeling paragraph and the U3 paragraph on claims against results.
1. Every completion condition and user decision in the requirement copies maps to changed code or a test; list the ones nothing in the diff produces.
2. No changed line contradicts a requirement or user decision (scope, behavior, error handling, stored format).
3. The change adds no behavior the requirements do not ask for.
4. Every claim in changed comments, docstrings, docs, or test names ("always", "never", "unchanged", "keeps") matches the code at the head.
5. Every rule in the AGENTS.md files on the changed paths is followed or the deviation is justified in the change itself.
