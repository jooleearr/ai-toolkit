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

## Render it so it displays

Write the diagram to a `.mmd` file and send it with `SendUserFile` (`display: "render"`) so it renders visually — the reader should see the diagram, not a block of Mermaid source they have to imagine. Put the file in a scratch/temp location, not the user's repo, unless they've asked to keep it.

Fallback: if file-send isn't available in the environment, emit a fenced ` ```mermaid ` block inline. Many surfaces render it; a raw block is still the last resort, never the goal.
