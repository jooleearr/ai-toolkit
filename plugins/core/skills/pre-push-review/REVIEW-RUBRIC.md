# Review rubric

The vocabulary for a pre-push review finding: the **category** that names the concern, the **severity** that ranks it, and the **Conventional Comments** line that states it. Consulted from step 6 of [`SKILL.md`](SKILL.md).

## Categories

Every finding sits in exactly one category. They double as the report's section order when there are many findings.

| Category | Covers |
| :------- | :----- |
| `scope-fit` | Does the change solve *this* problem and stay inside the agreed scope? Unmet acceptance criteria, scope creep, non-goals breached, broken assumptions. **The category this skill owns** — the others are shared with `code-review`. |
| `correctness` | Logic bugs, wrong results, unhandled edge cases. Mostly folded in from `code-review`. |
| `architecture` | Boundary and layer fit; a structural change smuggled in under a feature. |
| `tests` | Behaviour coverage of the acceptance criteria; tests that assert behaviour, not implementation. |
| `readability` | Naming, dead code, units that fight the surrounding idiom. |
| `security` | Auth, secrets, input handling, permissions. Folded in from `security-review` where it ran. |
| `observability` | Logging, metrics, tracing the change warrants — diagnosable in production, no secrets leaked. |

## Severity

Three levels, and the decoration each maps to. Rank the report by this order.

| Severity | Meaning | Conventional decoration |
| :------- | :------ | :---------------------- |
| **blocker** | Must be fixed before push. Unmet acceptance criterion, "solved the wrong problem", broken assumption, smuggled structural change, security hole. | `(blocking)` |
| **issue** | Should be fixed, but a reviewer could reasonably accept it with a follow-up. | `(non-blocking)` or `(if-minor)` |
| **nitpick** | Minor polish; author's discretion. | `(non-blocking)` |

The **verdict** is mechanical: any blocker → *needs work*; zero blockers → *ready to push* (issues and nits listed, but not gating).

## Conventional Comments format

Findings use [Conventional Comments](https://conventionalcomments.org/) so the output is consistent and skimmable:

```
<label> [decorations]: <subject>

[optional discussion / suggested fix]
```

**Labels:** `praise:` · `nitpick:` · `suggestion:` · `issue:` · `todo:` · `question:` · `thought:` · `chore:`

**Decorations:** `(blocking)` · `(non-blocking)` · `(if-minor)`

Lead with `praise:` where the change earns it — a review that only lists faults reads as adversarial, and genuine praise costs almost nothing.

## Worked example

Verdict line, then findings ordered blocker-first:

> **Needs work** — 1 blocker, 2 non-blocking.

- `scope-fit` — **issue (blocking):** `issue (blocking): AC-3 ("existing sessions stay valid across the rollout") is never exercised — the migration invalidates every session on deploy. This is the ticket's stated must-not-break, not a nit.`
- `architecture` — **issue:** `suggestion (non-blocking): the new retry loop lives in the controller; the plan put I/O concerns in the service layer. Move it to keep the boundary the hand-off doc agreed.`
- `tests` — **nitpick:** `nitpick (non-blocking): the happy-path test asserts the internal cache key rather than the returned value — it'll pass through a refactor that breaks the behaviour.`
