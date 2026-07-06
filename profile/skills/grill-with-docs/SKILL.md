---
name: grill-with-docs
description: >-
  Grilling session that challenges your plan against the existing domain
  model. Sharpens terminology and updates CONTEXT.md and ADRs inline. Use when
  user says "grill with docs", "challenge my plan", "domain review", or wants
  to refine a plan against existing documentation.
---

# Grill With Docs

A grilling session — but grounded in the project's domain model. You challenge the user's plan against existing documentation, sharpen vague terminology, and update docs inline.

## Before you start

1. Read `CONTEXT.md` (or equivalent domain glossary) if it exists
2. Read `docs/adr/` for existing architectural decisions
3. Understand the domain vocabulary before asking questions

## The Grill

### Rules

1. **One question at a time.** Don't front-load.
2. **Challenge terminology.** If the user uses a term not in CONTEXT.md, stop and clarify:
   - "You said 'sync' — do you mean real-time replication or periodic batch update?"
   - Then propose a CONTEXT.md entry for the agreed definition
3. **Discuss concrete scenarios.** "What happens when X fails?" / "Walk me through a user doing Y."
4. **Cross-reference with code.** "The current `UserService` already handles Z — is this replacing it or extending it?"
5. **Identify decisions.** When a trade-off emerges, name it:
   - "This is a decision: eager vs lazy loading. Want me to draft an ADR?"

### Inline documentation updates

As the conversation clarifies things:

- **New term agreed** -> Propose a CONTEXT.md addition (see [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md))
- **Trade-off resolved** -> Offer to create an ADR (see [ADR-FORMAT.md](ADR-FORMAT.md))
- **Contradiction found** -> Flag it: "CONTEXT.md says X but you're describing Y"

### When to stop

Stop when:

- Every branch of the decision tree has been resolved
- The user has a clear next action
- All new terms are proposed for CONTEXT.md
- Hard-to-reverse decisions have ADR drafts

## After the Grill

Summarize:

1. **Decisions made** (with ADR references if created)
2. **Terms defined** (with CONTEXT.md updates)
3. **Open questions** (anything still unresolved)
4. **Recommended next step**
