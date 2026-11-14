# Method: tests pin the contract
Apply rv `~/.agents/skills/rv/SKILL.md` U3's paragraph on tests, the Software Testing sections of `~/.agents/skills/python-expert/SKILL.md`, and the AGENTS.md files under the repository's test directories.
1. Each changed behavior has a test that would fail on the code before the change; name the test or report the behavior without one.
2. Tests observe public behavior, not private names or internal state.
3. Boundary and error paths of the change are covered.
4. Fakes and fixtures return the same shape as the real implementation they stand for.
5. Assertions are exact where the contract is exact (full string or value equality, not a suffix or a truthiness check); no skip, xfail, or weakened assertion hides a failure.
