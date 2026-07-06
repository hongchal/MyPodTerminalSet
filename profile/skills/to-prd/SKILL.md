---
name: to-prd
description: >-
  Turn the current conversation context into a PRD and submit it as a GitHub
  issue. No interview - just synthesizes what you've already discussed. Use
  when user says "to PRD", "make a PRD from this", or wants to capture a
  conversation as a product requirement.
---

# To PRD

Synthesize the current conversation context and codebase understanding into a Product Requirements Document. No interview -- just capture what's already been discussed.

## Process

1. **Review the conversation** - extract all decisions, requirements, and constraints discussed
2. **Explore the codebase** - understand which modules are affected and identify deep modules
3. **Draft the PRD** using the template below
4. **Present to user** for review
5. **Create a GitHub issue** with the PRD content

## Template

```markdown
# [Feature Name]

## Problem Statement
What problem are we solving? Why now?

## Solution
High-level approach. What changes, what stays the same.

## User Stories
- As a [role], I want [capability] so that [benefit]

## Implementation Decisions
Decisions already made during discussion:
- [Decision]: [Rationale]

### Modules Affected
Which modules change and how:
- `module-name`: [What changes]

### Deep Module Opportunities
Where can we deepen interfaces:
- [Module]: [Opportunity]

## Testing Decisions
- What level of testing (unit/integration/e2e)
- Which behaviors to test
- Which seams to test through

## Out of Scope
Explicitly excluded from this work:
- [Item]: [Why excluded]
```

## Guidelines

- Use the project's domain vocabulary from CONTEXT.md
- Reference relevant ADRs from docs/adr/
- Focus on WHAT and WHY, not HOW (implementation details belong in the code)
- Keep it concise -- a PRD that nobody reads is worse than no PRD
