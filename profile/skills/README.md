# profile/skills/

Custom skills. Deployed to `~/.claude/skills/` by `55-claude-profile.sh`.

## 형식
디렉터리: `<skill-name>/SKILL.md` (+ 선택: `scripts/`, `references/`, `templates/`)

```markdown
---
name: skill-name
description: 트리거 키워드 포함된 1-1024자 설명 (에이전트가 검색)
---

# Skill name
## Overview
## When to Use
## Process
## Examples
```

플러그인(OMC, bkit, superskillret) 스킬과 이름 충돌 주의. 사용자 정의가 우선.

## Adopted skills (productivity)

Vendored from [mattpocock/skills](https://github.com/mattpocock/skills)-derived versions
battle-tested in the `qwen3-nvfp4-quantize` project. Self-contained — no dependency on
`/grilling` or `setup-matt-pocock-skills` (unlike current upstream).

| Skill | Purpose |
|---|---|
| `grill-me` | Relentless interview to stress-test a plan/design before building |
| `grill-with-docs` | Grilling session that challenges a plan against CONTEXT.md / ADRs |
| `tdd` | Red-green-refactor loop with integration-style, behavior-first tests |
| `to-prd` | Turn current conversation into a PRD, filed as a GitHub issue |
| `to-issues` | Break a plan/PRD into vertical-slice GitHub issues |
| `improve-codebase-architecture` | Find shallow modules and propose deepening opportunities |

To adopt a new skill: copy its directory here, add a row to this table,
and update the "Adopted skills" section in `CLAUDE.user.md`.
