# Method: concurrency, failure, and recovery
Apply `~/.agents/skills/parallel-expert/SKILL.md` (PDC-Coordination: task lifetimes, failure isolation, idempotency and crash recovery) and rv `~/.agents/skills/rv/SKILL.md` U3's tracing of partial completion, retries, and cancellation.
1. Concurrent runs of the same work (two workers, a retry, a re-upload) end in one defined state; name the lock, unique key, or idempotency key that guarantees it.
2. A crash, timeout, or cancellation between steps leaves a state the recovery path resumes from; name that path at its file:line.
3. Ordering (A before B) is enforced by a mechanism, not by timing.
4. Queues, pools, and retries are bounded; nothing waits forever or retries without a limit.
