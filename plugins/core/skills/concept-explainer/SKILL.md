---
name: concept-explainer
description: Use when you're working in an unfamiliar area and want to understand a concept, system, or piece of jargon — builds a durable mental model in plain terms, leaning on an analogy, an end-to-end flow through the system, and a rendered diagram, grounded in your own codebase where one is present. Companion to the plan → implement → pre-push-review pipeline, used throughout. Progressive: starts shallow and goes one rung deeper on request.
---

# Concept explainer

Build a durable **mental model** in the reader's head — not a one-off answer they forget by tomorrow. The measure of success is that they could re-explain the thing themselves afterwards.

Three habits carry the whole skill. **Scaffold**: meet the reader where they are and add one rung at a time, shallow before deep — you can always go deeper, but you can't un-confuse. **Follow the flow**: explain how the thing *moves through the system* end to end, never a term defined in isolation. **Plain voice**: write the way you'd say it out loud — short, concrete words, no filler and no LLM tics (nothing is "load-bearing", nothing "delves"). If a plainer word exists, use it.

## 1. Calibrate

Gauge what the reader already knows, so you neither talk over them nor belabour what's obvious. Infer their level from how they asked; when that's unclear, ask **one** quick question — their background, or the nearest thing they already understand — and anchor the explanation to it. Pick a deliberately shallow starting rung.

**Completion criterion:** you know roughly what the reader already knows and where to start.

## 2. Ground it in the code

If a codebase is present, find where the concept actually lives *before* explaining it — spawn an Explore agent for the real files, types, and entry points when the surface is large. This anchors the explanation to *their* system rather than the abstract textbook version. With no repo, or a concept genuinely external to it (a protocol, a maths idea), stay general and say so.

**Completion criterion:** either the concrete code the concept touches is identified, or you've confirmed there is nothing local to anchor to.

## 3. Explain in the shape

Deliver the explanation in a consistent **shape**, the short version first:

- **Analogy** — one concrete, everyday analogy before any precise detail.
- **Plain-terms definition** — what it is in the fewest jargon words; introduce each technical term only *after* its plain-language stand-in.
- **End-to-end flow** — trace how it actually moves through the system, start to finish. Follow the flow; don't just name the parts.
- **Where you'll see this in our code** — point at the concrete files and functions from step 2 (omit when nothing is local).

A few sentences per part, not a wall of text — depth is step 5's job.

**Completion criterion:** every part of the shape delivered (three when there's no codebase), each in plain terms.

## 4. Draw it

Draw a diagram *when it genuinely earns its place* — when the concept has structure or a flow that's easier to see than to read (a pipeline, a state machine, a hierarchy). Skip it when prose already makes the model clear; a diagram of something simple is noise. When you do draw one, choose the type that fits and deliver it so the reader actually sees it *rendered* — on a terminal that means writing it to a file they can open, not a raw Mermaid block they have to imagine. See [`DIAGRAMS.md`](DIAGRAMS.md) for type selection and per-surface rendering — and make it match the flow you traced in step 3.

**Completion criterion:** either a rendered diagram the reader can see, consistent with the step 3 flow, or a deliberate decision that one wouldn't add understanding here.

## 5. Check, then deepen

Confirm the model landed before adding to it. Invite the reader to explain it back, or pose one quick comprehension check aimed at the part most likely to be shaky. Then go **one rung deeper** only where they want it — depth on demand, not by default; loop back through the shape for the deeper rung. If the reader wants to keep the explanation, offer to record it in the repo's glossary (`docs/CONTEXT.md` or equivalent) rather than leaving it ephemeral.

**Completion criterion:** the reader has confirmed the model landed (or named the gap), and any requested deeper rung has been delivered.
