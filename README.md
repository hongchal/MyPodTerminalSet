# MyPodTerminalSet

GPU 클러스터 pod에서 Claude Code CLI + 개발 환경을 한 번에 셋업하는 부트스트랩 스크립트.

새 pod 띄울 때마다 `git clone` → `./bootstrap.sh` 두 줄로 동일한 환경 복원.

## Quick start (새 pod에서)

### 가장 짧은 방법 — 원격 install (git 없어도 됨)
```bash
curl -fsSL https://raw.githubusercontent.com/hongchal/MyPodTerminalSet/master/install.sh | bash
```
`install.sh`가 (1) git 없으면 자동 설치 (apt/apk/dnf/yum) (2) `/DATA1/hongcheol/dotfiles`에 clone (3) `bootstrap.sh` 실행까지 다 처리.

`/DATA1/hongcheol`이 없는 머신에선 자동으로 `~/MyPodTerminalSet`으로 fallback.

### 환경변수로 커스터마이즈
```bash
MTS_BRANCH=dev MTS_MODULES=tmux,fzf \
  curl -fsSL https://raw.githubusercontent.com/hongchal/MyPodTerminalSet/master/install.sh | bash
```

| Env | 기본값 | 용도 |
|-----|--------|------|
| `MTS_REPO` | `https://github.com/hongchal/MyPodTerminalSet.git` | 다른 fork 쓸 때 |
| `MTS_BRANCH` | `master` | 실험 브랜치 |
| `MTS_DEST` | `/DATA1/hongcheol/dotfiles` (없으면 `~/MyPodTerminalSet`) | clone 위치 |
| `MTS_MODULES` | `all` | 일부만 실행 (`tmux,fzf`) |

### 수동 (git이 이미 있을 때)
```bash
# 안전한 preflight: git 없는 minimal 이미지 대비
command -v git >/dev/null || (apt update && apt install -y git)

git clone https://github.com/hongchal/MyPodTerminalSet.git /DATA1/hongcheol/dotfiles
cd /DATA1/hongcheol/dotfiles
./bootstrap.sh
source ~/.bashrc
tmux new -s work
```

## 무엇을 깔아주나

| 모듈 | 설치/적용 |
|------|-----------|
| `00-base.sh` | apt essentials (curl, git, build-essential, rsync) |
| `10-node.sh` | Node.js 20 (NodeSource) |
| `20-claude.sh` | `@anthropic-ai/claude-code` CLI |
| `25-claude-sync.sh` | `~/.claude` ↔ `/DATA1/hongcheol/.claude` 안전 마이그레이션 + symlink |
| `26-claude-plugins.sh` | `~/.claude/settings.json`에 마켓플레이스(omc, bkit, thakicloud) + 플러그인 enable + 권한/언어/env 선언. 첫 `claude` 실행 시 플러그인 자동 fetch |
| `28-mcp-servers.sh` | `config/mcp-servers.json` 매니페스트의 standalone MCP 서버 등록 (플러그인 번들 MCP는 26이 처리) |
| `30-cli-tools.sh` | tmux, ripgrep, bat, fd, htop, ncdu, tree, gh, lazygit, delta, direnv (jq는 00-base에서) |
| `55-claude-profile.sh` | `profile/{agents,commands,skills}/` → `~/.claude/{agents,commands,skills}/` symlink deploy (사용자 커스텀 보관) |
| `56-claude-vault.sh` | `vault/rules/*.md` → `~/.claude/CLAUDE.user.md` 빌드. OMC의 글로벌 CLAUDE.md와 분리 |
| `35-fzf.sh` | fzf (git 설치, 최신 버전) |
| `40-python.sh` | uv, nvitop, ipython |
| `50-bash.sh` | `~/.bashrc` 추가 (history, alias, prompt with git, fzf) |
| `60-tmux.sh` | `~/.tmux.conf` (prefix=Ctrl+a, mouse on, vim nav, 상태바) |
| `70-secrets.sh` | `/DATA1/hongcheol/.secrets/` 템플릿 생성 (평문, chmod 600) |
| `80-git.sh` | git aliases, delta pager, hongchal/thakicloud push 헬퍼 |
| `99-done.sh` | 마커 + 마무리 안내 |

## 부분 실행

```bash
./bootstrap.sh                # 전체
./bootstrap.sh claude,tmux    # 특정 모듈만
```

## /DATA1 영속 디렉터리 구조

```
/DATA1/hongcheol/
├── .claude/         ← Claude 설정/메모리/플러그인 (symlinked from ~/.claude)
├── .secrets/        ← API 키 평문 보관 (chmod 700/600)
├── .config/gh/      ← GitHub CLI 인증 (symlinked from ~/.config/gh)
├── .ssh-backup/     ← SSH 키 백업
├── dotfiles/        ← 이 repo clone 위치
└── workspace/       ← 실제 코드
```

## 시크릿 확인

```bash
bash scripts/secrets-status.sh
# 또는 alias 등록 후
secrets-status
```

## 컨벤션

- 모든 모듈은 **idempotent** — 두 번 돌려도 안전
- 시크릿은 git에 **절대** 안 들어감 (whitelist .gitignore)
- 실제 키 값은 사용자가 첫 실행 후 `/DATA1/hongcheol/.secrets/*.env` 수동 편집

## 라이선스

MIT
