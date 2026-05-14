# profile/agents/

Custom sub-agent markdown files. Deployed to `~/.claude/agents/` by `55-claude-profile.sh`.

## 형식
파일명: `<agent-name>.md`
프론트매터:
```markdown
---
name: my-agent
description: 한 줄 설명
tools: Bash, Read, Edit, Glob, Grep
model: sonnet
---

# Agent body
...
```

## 예시 (pyj-claude 기반)
- `k8s-agent.md` — 쿠버네티스 작업 위임
- `task-agent.md` — 일반 작업
- `web-agent.md` — 웹 리서치
- `token-auditor.md` — 토큰 사용량 감사

플러그인이 제공하는 agent와 이름 충돌 주의 — 같은 이름이면 사용자 정의가 우선됨.
