# profile/commands/

Custom slash commands. Deployed to `~/.claude/commands/` by `55-claude-profile.sh`.

## 형식
파일명: `<command>.md` → `/command-name` 으로 호출

```markdown
---
description: 한 줄 설명
allowed-tools: Bash, Read
argument-hint: <arg description>
---

명령 본문 (Claude에게 전달될 프롬프트). 인자는 $ARGUMENTS 변수로 참조.
```

## 아이디어
- `/pod-status` — kubectl로 현재 pod 상태 요약
- `/secret-check` — secrets-status 호출 + 부족한 키 안내
- `/skillret-train` — SkillRet 학습 잡 시작 표준 명령
