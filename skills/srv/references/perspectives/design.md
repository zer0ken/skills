# Method: concepts, structure, and quality ceiling
Apply rv `~/.agents/skills/rv/SKILL.md` U2 questions 0, 1, and 2, and the Software Design sections of `~/.agents/skills/python-expert/SKILL.md`.
1. Every unit the change introduces or touches (module, class, function, field, status value, prompt, stage) has one sentence that decides membership, found in code, a type, a schema, or a document; list each unit without one.
2. The change removes the cause of the problem it answers, not only the symptom; name the cause from the requirement and the code.
3. Build one feasible alternative structure (data flow, state ownership, responsibility placement, call cost) and judge whether the change is worse than it.
4. Where the structure allows better, point at the implementation, prompt, query, or test that falls short.
