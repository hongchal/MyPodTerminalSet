---
name: improve-codebase-architecture
description: >-
  Find deepening opportunities in a codebase. Propose architectural
  improvements informed by the domain language and documented decisions. Use
  when user says "improve architecture", "find shallow modules", "deepening
  opportunities", or wants to reduce complexity and improve code depth.
---

# Improve Codebase Architecture

Find and propose "deepening opportunities" - places where shallow modules can be turned into deep ones, improving testability, maintainability and AI-navigability.

## Glossary

See [LANGUAGE.md](LANGUAGE.md) for shared vocabulary:

- **Module**: Unit of code with an interface and implementation
- **Interface**: What callers see (API, types, function signatures)
- **Implementation**: Hidden internals
- **Depth**: Ratio of implementation complexity to interface simplicity
- **Seam**: Boundary where dependencies can be substituted
- **Adapter**: Thin wrapper making an external dependency conform to an internal interface
- **Leverage**: Capability delivered per unit of interface complexity
- **Locality**: How much of a change is contained within one module

## Process

### 1. Explore

Scan the codebase for:

- **Shallow modules** - lots of interface, little implementation
- **Pass-through methods** - functions that just delegate
- **Leaky abstractions** - internal details exposed in interfaces
- **Missing seams** - places where testing requires the real dependency
- **Scattered changes** - features that touch many modules (low locality)

Use the domain glossary to understand module naming and boundaries.

### 2. Present candidates

For each opportunity, explain:

1. **What's shallow** - the current state
2. **What deepening looks like** - the proposed improvement
3. **Risk** - what could go wrong
4. **Dependencies** - what depends on this (see [DEEPENING.md](DEEPENING.md) for dependency classification)

### 3. Grilling loop

For each candidate the user is interested in:

1. Present the "Design It Twice" options (see [INTERFACE-DESIGN.md](INTERFACE-DESIGN.md))
2. Quiz the user on trade-offs
3. Agree on approach
4. Document the decision

### 4. Implementation

When the user approves a deepening:

1. Write the regression test at the correct seam **first**
2. Deepen the module
3. Verify tests pass
4. Clean up any adapters or seams that are no longer needed

## What to Look For

Good deepening candidates:

- Modules with many parameters that could be simplified
- Classes with too many public methods
- Functions that require callers to manage state
- Code where adding a feature requires touching 5+ files
- Test files that are harder to read than the implementation

Bad deepening candidates:

- Modules that are already thin wrappers by design (adapters)
- Code that rarely changes
- Interfaces mandated by external APIs
