# Method: model calls, prompts, and output contracts
Apply `~/.agents/skills/llm-expert/SKILL.md` sections 2 (structured output and its contract), 4 (diagnosis of bad results), 5 (prompt engineering), and 9 (serving resources and repeated work).
1. Each changed prompt and its output schema agree: every field the code reads is requested and constrained; nothing the prompt asks for is ignored by the code.
2. The prompt holds no conflicting instructions, and its wording matches the decision the code makes from the output.
3. Invalid, partial, or refused model output has a defined handling path that neither crashes nor silently accepts it.
4. No evaluation answer or test fixture content leaks into a prompt or product code.
5. The number of model calls per unit is the fewest that decide the outcome; calls whose result cannot change it are reported.
