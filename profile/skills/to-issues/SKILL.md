---
name: to-issues
description: >-
  Break a plan, spec, or PRD into independently-grabbable GitHub issues using
  vertical slices (tracer bullets). Use when user says "to issues", "break
  into issues", "create implementation tickets", or has a plan ready for
  execution.
disable-model-invocation: true
---

# To Issues

Break any plan, spec, or PRD into independently-grabbable backlog issues. Each issue is a vertical slice - a tracer bullet through the entire system that can be picked up and completed without depending on the other slices.

## Process

### 1. Gather context

- Read the plan/spec/PRD the user is referencing
- Identify the modules, APIs, and data models involved
- Check the project's domain glossary for shared vocabulary
- Check `docs/adr/` for relevant architectural decisions
- Look at past issues for formatting conventions

### 2. Draft vertical slices

Each slice must:

- **Be independently shippable** - it works end-to-end on its own
- **Touch every layer** - DB, API, UI as needed for that slice
- **Deliver visible value** - someone can see/test the change

Bad slicing (horizontal):
```
Issue 1: Create database schema
Issue 2: Build API endpoints
Issue 3: Build UI components
```

Good slicing (vertical):
```
Issue 1: User can create a project (DB + API + UI)
Issue 2: User can invite members to a project (DB + API + UI + email)
Issue 3: User can archive a project (DB + API + UI)
```

### 3. Quiz the user

Present the proposed slices and ask:

- Are these the right boundaries?
- Is the ordering correct? (dependency-wise)
- Any slices that should be split or merged?
- What's the acceptance criteria for each?

### 4. Publish

For each approved slice, create a GitHub issue with:

- **Title**: Action-oriented ("User can X" or "System does Y")
- **Body**: Context, acceptance criteria, technical notes
- **Labels**: As appropriate for the project

Use the project's issue conventions if they exist.
