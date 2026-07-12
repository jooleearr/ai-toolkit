# Diagrams — rendering a mental model

Disclosed reference for [`concept-explainer`](SKILL.md), step 4. A diagram earns its place only when it shows something prose makes the reader hold in their head — a flow, a structure, a lifecycle. Pick the type that fits, keep it small, and render it so it actually displays.

## Choose the type

One idea per diagram — pick the single type that fits what step 3 traced:

| You're explaining… | Mermaid type |
| :----------------- | :----------- |
| how a request/message moves between parts over time | `sequenceDiagram` |
| branching logic, a decision, or a data pipeline | `flowchart` |
| how components/services connect (the static shape) | `flowchart` / `graph` |
| the lifecycle an entity moves through | `stateDiagram-v2` |
| the shape of the data (fields, relationships) | `classDiagram` / `erDiagram` |

The end-to-end flow is the common case, so `sequenceDiagram` and `flowchart` cover most explanations. When two views genuinely help (e.g. structure *and* flow), draw two small diagrams rather than one crowded one.

## Keep it legible

- **One idea, ~5–9 nodes.** A diagram that needs a legend is too big — split it.
- **Plain-language labels** that match the words used in the explanation, so the diagram and the prose reinforce one model.
- Show only the parts the explanation named; leave the rest out.

## Render it where the reader can see it

A diagram only pays off if the reader sees it *rendered*, not the Mermaid source. A raw ` ```mermaid ` fence renders on some surfaces and lands as an unreadable wall of `flowchart TD` / `-->` syntax on others — so match the delivery to the surface, and treat a raw block dumped where nothing renders it as the failure to avoid, never the goal.

- **Terminal (assume this by default for a CLI).** Nothing renders inline here, so write the diagram to a file in the project's ephemeral scratch directory and point the reader at the path — they open it in an editor's Mermaid preview. Discover where ephemeral files go rather than assuming: prefer an existing gitignored scratch dir (check `.gitignore` for `.scratch/`, `tmp/`, `scratch/`); fall back to `.scratch/` (add it to `.gitignore` if absent). Name the file for the concept: `.scratch/<concept>-diagram.mmd`.
- **A surface that previews a sent file** (an app/side-panel that renders attachments). Write the `.mmd` and send it with `SendUserFile` (`display: "render"`).
- **A surface that renders Mermaid inline** (an artifact, a chat UI with Mermaid support). Emit a fenced ` ```mermaid ` block — it renders in place.

Whichever path fits, always name the file path or point at the rendered diagram in your reply, so it's discoverable.
