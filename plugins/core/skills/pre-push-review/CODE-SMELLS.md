# Code smells

The catalogue for the **code-smell pass** — Martin Fowler's smells from *Refactoring* (2nd ed.), each paired with the signals that betray it in a diff and the refactoring that removes it. Consulted from step 3 of [`SKILL.md`](SKILL.md). Described in this skill's own words, not the book's.

A smell is a *hint*, not a verdict: a surface sign that the design may be paying for something. Every finding here is **advisory** — it names what looks off and points at the fix, and the author decides. Keep that in mind while reading the catalogue below.

## How to use this catalogue

- **Diff-scoped.** Flag a smell only where the change under review *introduces* it or *makes it worse*. A smell the diff merely sits next to, and neither created nor deepened, is out of scope — reviewing the whole codebase is not this pass's job.
- **Precision over recall.** A wrong flag spends the author's trust; a missed one costs little. When a signal is borderline, stay silent. Better to surface three smells the author agrees with than ten they wave away.
- **Cite the instance.** Every finding names a concrete `file:line` (or line range) and says which signal fired — never "this file smells".
- **Pair with the refactoring.** A smell without its fix is a complaint. Name the specific refactoring from the row, so the finding ends on an action.
- **Severity is advisory by default.** Code smells land as `issue` or `nitpick`, never a `blocker` on their own — see [`REVIEW-RUBRIC.md`](REVIEW-RUBRIC.md). A smell only blocks when it *also* trips another category (e.g. a duplicated branch that drops a case is `correctness`).

## Naming & comprehension

| Smell | Signals in the diff | Suggested refactoring |
| :---- | :------------------ | :-------------------- |
| **Mysterious Name** | A new function, variable, or type whose name doesn't say what it does or holds — `data`, `tmp`, `handle2`, `process`; a name that contradicts the body. | Rename Variable / Rename Function until the name states intent; if you can't name it, the design is probably unclear too. |
| **Comments** (as deodorant) | A comment that explains *what* a tangled block does, standing in for code that could say it itself. Distinct from comments recording *why*, which are welcome. | Extract Function with an intention-revealing name; Rename to fold the explanation into the code, leaving comments for rationale only. |

## Bloaters

| Smell | Signals in the diff | Suggested refactoring |
| :---- | :------------------ | :-------------------- |
| **Long Function** | A function that grows well past a screen, mixes several levels of abstraction, or is sectioned by blank lines and banner comments. | Extract Function per section; Replace Temp with Query; Decompose Conditional. |
| **Large Class** | A class accreting fields and methods across several responsibilities; the diff piles more onto an already-crowded type. | Extract Class / Extract Subclass along the responsibility seam; group the fields that vary together first. |
| **Long Parameter List** | Four-plus parameters, or a run of booleans/flags that configure behaviour; callers passing values they just unpacked. | Introduce Parameter Object; Preserve Whole Object; Replace Parameter with Query for anything derivable. |
| **Data Clumps** | The same two-or-three fields travelling together — through parameter lists, in field declarations, as repeated `x, y, z`. | Introduce Parameter Object or Extract Class so the clump becomes one named thing. |
| **Primitive Obsession** | Domain concepts carried as bare strings/ints — a phone number as `string`, money as `float`, a status as a magic constant; validation of the same primitive repeated. | Replace Primitive with Object; Replace Type Code with Subclasses / State; introduce a small value type. |

## Data & state

| Smell | Signals in the diff | Suggested refactoring |
| :---- | :------------------ | :-------------------- |
| **Global Data** | New module-level mutable state, a singleton written from many sites, a global touched by unrelated code. | Encapsulate Variable behind an accessor so mutation has one guarded door; narrow the scope. |
| **Mutable Data** | A structure mutated in place across far-apart sites; a variable reassigned to mean different things; shared state updated without a single owner. | Encapsulate Variable; Split Variable; Replace Derived Variable with Query; prefer producing new values over in-place updates. |
| **Temporary Field** | A field set only in certain circumstances and null/unused otherwise; an instance variable that exists just to pass state between two methods. | Extract Class for the sometimes-populated fields; Introduce Special Case for the empty state. |
| **Data Class** | A class that is only fields plus getters/setters, with the behaviour that acts on them living elsewhere. | Move the operating logic onto the class (Move Function); Encapsulate Record; make it earn its methods. |

## Change preventers

| Smell | Signals in the diff | Suggested refactoring |
| :---- | :------------------ | :-------------------- |
| **Divergent Change** | One module edited for unrelated reasons — this diff changes it for reason A while recent history changed it for reason B. | Split Phase; Extract Class so each axis of change has its own home. |
| **Shotgun Surgery** | One logical change forces small edits scattered across many files/classes in the same diff. | Move Function / Move Field to pull the scattered logic together; Combine Functions into Class. |
| **Repeated Switches** | The same `switch`/`if-else` on a type code appearing in more than one place; the diff adds a new case and must edit every copy. | Replace Conditional with Polymorphism; Replace Type Code with Subclasses. |

## Couplers

| Smell | Signals in the diff | Suggested refactoring |
| :---- | :------------------ | :-------------------- |
| **Feature Envy** | A method that reaches repeatedly into another object's data — more calls to `other.x`, `other.y` than to its own. | Move Function to the data it envies; Extract Function then move the envious part. |
| **Message Chains** | A train of accessors — `a.getB().getC().getD()` — coupling the caller to a deep structure. | Hide Delegate; Extract Function for what the chain ultimately computes. |
| **Middle Man** | A class most of whose methods just forward to another object. | Remove Middle Man and let callers talk to the delegate; Inline Function for the pass-throughs. |
| **Insider Trading** | Modules reaching into each other's internals — private fields, back-channel coupling — instead of a stated interface. | Move Function / Move Field to reduce the shared surface; introduce an explicit intermediary. |

## Dispensables & generality

| Smell | Signals in the diff | Suggested refactoring |
| :---- | :------------------ | :-------------------- |
| **Duplicated Code** | The same expression or block appearing twice-plus, or near-identical branches differing only in a value. | Extract Function; Pull Up Method; Slide Statements then extract the common part. |
| **Lazy Element** | A class, function, or layer that no longer earns its keep — a one-line delegate, a class with a single trivial method. | Inline Function / Inline Class; Collapse Hierarchy. |
| **Speculative Generality** | Abstraction added for a future that isn't here — an unused hook, an interface with one implementer, a parameter no caller sets. | Collapse Hierarchy; Inline Function; Remove Dead Code and the unused parameter. |
| **Loops** | A hand-rolled loop that accumulates/filters/maps where a collection pipeline would read as the intent. | Replace Loop with Pipeline (map / filter / reduce). |

## Inheritance & interface

| Smell | Signals in the diff | Suggested refactoring |
| :---- | :------------------ | :-------------------- |
| **Alternative Classes with Different Interfaces** | Two classes doing the same job with mismatched method names/signatures, so callers can't swap them. | Rename Function / Change Function Declaration to align them; Extract Superclass once they match. |
| **Refused Bequest** | A subclass that ignores or throws on much of what it inherits — inheriting for a slice while rejecting the rest. | Replace Superclass with Delegate (favour composition); Push Down Method/Field to where they're wanted. |

## The pass in one line

Walk the diff once against this catalogue, flag only the smells the change **introduces or worsens**, cite each `file:line` with the signal that fired and the paired refactoring, and stay silent when a signal is borderline.
