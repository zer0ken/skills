# Follow-up questions

After verifying a round, the operator writes follow-up questions so the next round digs where the swarm was weak. Each question is one sentence or a short paragraph about one place, answerable by reading code at the head; it names the perspective method file whose items apply.

Write a question for each of these:

1. Each PLAUSIBLE cluster: the execution or tracing that would decide it (example: "Does any caller of `f` at the head pass an empty list, and what does `f` return then?").
2. Each CONFIRMED cluster: whether the same cause appears elsewhere (rv U5 propagation): the other callers, backends, fakes, prompts or documents that share it.
3. Each CONFIRMED or PLAUSIBLE cluster raised by only one session: the condition under which it occurs, so a second reading confirms or rejects it.
4. Each changed file or hunk that no reviewer cited and no checklist item reported as checked: a question naming the hunk and the perspective whose items apply to it.

A question may name the counter-argument the reviewer must also weigh (example: "check whether the exception is intended"), but it does not carry the operator's verdict, the cluster text, or other reviewers' suggestions. Each question file holds the question, the round-1 brief path, the perspective method file, the output path `round-<k>/Q<n>-result.md`, and a length limit for the output (140 lines in the first run). The reviewer reads only what the question needs and does not repeat the perspective sweep.

One session per question, launched together. In the first run the seven round-2 questions, one session each, reached 77.8% precision against 34.1% for the perspective sweep. A question whose answer repeats a REJECTED suggestion is closed with the line that rejects it.
