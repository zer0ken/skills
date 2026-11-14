# Method: imports, placement, and names
Apply rv `~/.agents/skills/rv/SKILL.md` U1 items 1, 2, 3, 4.5-4.6, and 5.
1. No layer inversion, bypass of a package's public path, private-name import, or import moved into a function to dodge a cycle.
2. Each new or moved file sits with its concept; no catch-all module, pass-through module, or split used in one place.
3. Names state the responsibility, match the repository's naming and singular/plural, and paired modules are named symmetrically.
4. Old names left after a move or rename (docs, tests, patch targets, serialized keys, settings) are reported with their location.
5. A precedent cited as grounds ("기존과 같다", "관례상") has a primary record; report one without.
