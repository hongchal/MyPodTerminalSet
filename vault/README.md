# vault/

룰 소스 모듈. `vault/rules/*.md` 들이 `scripts/build.sh`에 의해 **`~/.claude/CLAUDE.user.md`** 로 합쳐집니다.

## 왜 분리하는가
글로벌 `~/.claude/CLAUDE.md`는 OMC 플러그인이 setup 시 자기 내용을 적기 때문에 직접 편집하면 OMC 업데이트 시 충돌. 그래서 **CLAUDE.user.md** 라는 별도 파일에 사용자 룰을 두고, OMC의 CLAUDE.md에서 `@CLAUDE.user.md` 참조 한 줄로 포함시키는 패턴.

## 구조
```
vault/
├── rules/
│   ├── 01-style.md         # 응답 스타일
│   ├── 02-workflow.md      # 작업 순서/규칙
│   ├── 03-env.md           # 환경/도구 alias
│   └── ...
└── scripts/
    └── build.sh            # rules 합쳐서 CLAUDE.user.md 생성
```

## 빌드
```
bash vault/scripts/build.sh
# → ~/.claude/CLAUDE.user.md 생성
```
`56-claude-vault.sh` 모듈이 부트스트랩에서 자동 호출.

## OMC의 CLAUDE.md와 연결
첫 셋업 후 한 번만:
```
# ~/.claude/CLAUDE.md 끝에 추가
@CLAUDE.user.md
```
이후 vault만 편집해서 빌드하면 OMC 룰 + 사용자 룰 둘 다 활성화.
