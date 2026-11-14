# Follow-up questions

After verifying a round, the operator writes follow-up questions so the next round digs where the swarm was weak. Each question is one sentence about one place, answerable by reading code at the head.

Write a question for each of these, in this order, and drop the rest when a round would exceed the session budget the procedure log shows the server served in round 1:

1. Each PLAUSIBLE cluster: the execution or tracing that would decide it (for example "Does any caller of `f` at the head pass an empty list, and what does `f` return then?").
2. Each CONFIRMED cluster: whether the same cause appears elsewhere (rv U5 propagation): the other callers, backends, fakes, prompts or documents that share it.
3. Each CONFIRMED or PLAUSIBLE cluster raised by only one session: the condition under which it occurs, so a second reading confirms or rejects it.
4. Each changed file or hunk that no reviewer cited and no checklist item reported as checked: a question naming the hunk and the perspective whose items apply to it.

Do not put the operator's verdict, the cluster text, or other reviewers' suggestions into the question; the reviewer gets the round-1 brief unchanged with one added line:

`Follow-up question (answer only this; report findings in the same format): <QUESTION>`

Two sessions per question, launched together, so a single wrong reading does not decide it. A question whose answer repeats a REJECTED suggestion is closed with the line that rejects it.
