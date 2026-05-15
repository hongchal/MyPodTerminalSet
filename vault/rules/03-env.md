# Environment

## Persistent storage
- 모든 영구 데이터는 `/DATA1/hongcheol/` 아래
- `~/.claude` → `/DATA1/hongcheol/.claude` symlink (25-claude-sync)
- `~/.omc` → `/DATA1/hongcheol/.omc` symlink (27-omc-sync) — OMC 플러그인 project memory/sessions/state
- `/DATA1/hongcheol/quantization/` — 양자화 작업 트리 (per-model 디렉토리 + lm-evaluation-harness 클론, IFEval)
- `/DATA1/hongcheol/nltk_data/` — NLTK 코퍼스 (NLTK_DATA env var로 참조, IFEval에 필요)
- 공통 ML/LLM 도구(transformers/vllm/lm-evaluation-harness+IFEval/nltk) 재설치: 41-ml-stack.sh
- 양자화 전용 도구(nvidia-modelopt) 재설치: 42-quant-tools.sh
- secrets: `/DATA1/hongcheol/.secrets/*.env` (chmod 600)

## Pod
- 베이스 이미지: `ghcr.io/thakicloud/pytorch:2.8-cu128-cp311-jammy`
- 노드 핀: `bdv2kr1-gpunode01` (/DATA1 호스트 마운트 위치)
- 새 pod 셋업: `curl -fsSL https://raw.githubusercontent.com/hongchal/MyPodTerminalSet/master/install.sh | bash`

## GitHub
- 개인 계정: `hongchal` (chal405@naver.com)
- 회사 계정: `chohongcheol-thakicloud`
- `hongchal/*` repo push: `env -u GITHUB_TOKEN -u GITHUB_USERNAME bash -c 'gh auth switch -u hongchal && git push'`
