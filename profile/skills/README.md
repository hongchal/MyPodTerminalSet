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
