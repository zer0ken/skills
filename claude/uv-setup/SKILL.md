---
name: uv-setup
description: "현재 프로젝트를 uv 기반 종속성 관리로 전환한다. uv 설치 → 기존 pip/poetry/pipenv 감지·마이그레이션 → pyproject.toml/uv.lock/.venv 셋업 → CLAUDE.md·AGENTS.md에 uv 규칙 기록. 이후 이 프로젝트에서 uv 워크플로가 강제된다. 또한 \"uv-setup update\" / \"업데이트\"로 자가 업데이트를 수행한다."
metadata:
  author: hrlee
  version: "1.0.0"
  domain: python-tooling
  triggers: uv, uv-setup, 종속성 관리, dependency management, pyproject, pip 마이그레이션, poetry 마이그레이션, venv, astral uv
  role: setup
  scope: project
  output-format: action
---

# uv-setup

현재 프로젝트를 [uv](https://docs.astral.sh/uv/) 기반 Python 종속성 관리로 전환하고, 이후 작업 시 uv 워크플로가 강제되도록 규칙 문서를 갱신한다.

## 사용법

```
/uv-setup
```

프로젝트 루트(또는 대상 프로젝트 디렉토리)에서 호출한다. 인자 없이 동작하며, 현재 상태를 감지하여 필요한 단계만 수행한다(멱등성).

인자가 `update` / `업데이트` / `check update`이면 셋업을 수행하지 말고 [Source & Updates](#source--updates)의 자가 업데이트 점검을 실행한다.

---

## 실행 절차

### Phase 0: 사전 확인

1. **대상 디렉토리 확정** — CWD가 Python 프로젝트 루트인지 확인. 워크트리(`.worktrees/`) 안이면 사용자에게 메인 프로젝트 대상인지 확인.
2. **uv 설치 여부 확인**:
   ```powershell
   uv --version
   ```
   - 설치되어 있으면 Phase 1로.
   - 미설치 시 **설치 시도**(아래 우선순위):
     ```powershell
     # 1순위: 공식 standalone 설치 스크립트 (Windows)
     powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
     # 실패 시 2순위: winget
     winget install --id=astral-sh.uv -e
     # 그래도 안 되면 3순위: pip
     pip install uv
     ```
   - 설치 후 새 셸에서 `uv --version`으로 검증. PATH 미반영 시 사용자에게 셸 재시작 안내.

### Phase 1: 기존 종속성 상태 감지

루트에서 다음을 조사하여 현재 관리 방식을 판별한다.

| 발견 파일 | 관리 방식 | 처리 |
|----------|----------|------|
| `pyproject.toml` + `[tool.poetry]` | Poetry | 마이그레이션 |
| `Pipfile` / `Pipfile.lock` | pipenv | 마이그레이션 |
| `requirements*.txt` | pip / pip-tools | 마이그레이션 |
| `setup.py` / `setup.cfg` (단독) | setuptools(legacy) | 마이그레이션 |
| `pyproject.toml` + `[project]` (PEP 621), uv.lock 없음 | 표준 | uv가 직접 사용 가능 → `uv sync` |
| `pyproject.toml` + `uv.lock` | **이미 uv** | 셋업 생략, Phase 3만 수행 |
| 아무것도 없음 | 신규 | `uv init` |
| `environment.yml` (conda) | conda | **자동 마이그레이션 불가** → 사용자에게 보고 후 결정 |

감지 결과와 계획할 처리를 사용자에게 한 줄로 보고한 뒤 진행한다.

### Phase 2: 마이그레이션 / 초기화

3. **마이그레이션 (poetry / pipenv / pip / pip-tools)** — 통합 도구 사용:
   ```powershell
   uvx migrate-to-uv --keep-current-data
   ```
   - `migrate-to-uv`는 관리 방식을 자동 감지하여 `[project]` PEP 621 형식으로 `pyproject.toml`을 변환하고 dev 그룹 등을 보존한다. 변환과 동시에 `uv lock`까지 수행한다.
   - **`--keep-current-data` 필수**: 이 플래그가 없으면 `requirements.txt`/`Pipfile`/poetry 블록 등 **원본을 자동 삭제**한다(CLAUDE.md "원본 비변형" 원칙 위반). 반드시 플래그를 붙여 원본을 남긴다.
   - 자동 감지 실패 시 명시: `uvx migrate-to-uv --keep-current-data --package-manager poetry|pipenv|pip|pip-tools`.

4. **requirements.txt만 있고 pyproject 없을 때** (migrate-to-uv가 처리하지 못한 경우 폴백):
   ```powershell
   uv init --bare
   uv add -r requirements.txt
   ```

5. **신규 프로젝트**:
   ```powershell
   uv init
   ```

6. **마이그레이션 후 원본 보존** — 위 `--keep-current-data` 플래그로 `requirements.txt`/`Pipfile`/poetry 블록 등이 보존된다(CLAUDE.md "원본 비변형" 원칙). 사용자에게 "마이그레이션 검증 후 직접 제거하라"고 안내만 한다.

### Phase 3: 환경 동기화 및 검증

7. **lock + 가상환경 생성**:
   ```powershell
   uv sync
   ```
   `.venv/`, `uv.lock` 생성 확인.
   - `No requires-python value found` 경고가 뜨면 `pyproject.toml`에 `requires-python`이 없는 것. 현재 인터프리터에 맞춰 `uv python pin <version>`으로 고정하거나 `pyproject.toml [project]`에 `requires-python = ">=3.x"`를 추가한 뒤 다시 `uv sync`.

8. **검증** — 실제로 동작하는지 확인(추정 금지):
   ```powershell
   uv run python --version
   ```
   테스트 러너가 있으면 `uv run pytest --collect-only` 등으로 환경 정상 여부 확인.

### Phase 4: 규칙 문서 갱신

**CLAUDE.md와 AGENTS.md 둘 다** 프로젝트 루트에서 갱신한다. 없으면 생성한다.

9. 아래 마커 블록을 삽입한다. **이미 마커가 있으면 블록 전체를 교체**(중복 방지). CLAUDE.md/AGENTS.md는 컨텍스트 파일이므로 블록 내용은 **영어로 작성**한다(언어 정책):

   ```markdown
   <!-- uv-managed:start -->
   ## Dependency Management (uv)

   This project manages dependencies with [uv](https://docs.astral.sh/uv/). **Do not use `pip`/`poetry`/`pipenv` directly.**

   | Task | Command |
   |------|---------|
   | Add dependency | `uv add <pkg>` |
   | Add dev dependency | `uv add --dev <pkg>` |
   | Remove dependency | `uv remove <pkg>` |
   | Sync environment (install) | `uv sync` |
   | Run a script/command | `uv run <cmd>` (e.g. `uv run python main.py`, `uv run pytest`) |
   | Update lock | `uv lock` |
   | Pin Python version | `uv python pin <version>` |

   **Rules:**
   - Never call `pip install` directly → use `uv add`.
   - Never hand-edit `requirements.txt` → manage dependencies in `pyproject.toml` via `uv`.
   - Do not manually activate the venv → run via `uv run` (it uses `.venv` automatically).
   - Commit `uv.lock`. Do not commit `.venv/`.
   - Setting up a fresh environment is a single `uv sync`.
   <!-- uv-managed:end -->
   ```

10. **`.gitignore` 확인** — `.venv/`가 없으면 추가. `uv.lock`은 ignore되지 않도록 확인.

### Phase 5: 보고

11. 사용자에게 요약 보고:
    - 수행한 단계(설치/마이그레이션/init 중 무엇)
    - 검증 결과(`uv run python --version` 출력)
    - 갱신한 문서(CLAUDE.md, AGENTS.md)
    - 사용자 후속 조치(원본 requirements 제거 검토 등)

---

## 핵심 원칙

### 1. 멱등성 — 재실행해도 안전
이미 uv 프로젝트면 셋업을 건너뛰고 규칙 문서/`.gitignore`만 점검·갱신한다. 마커 블록은 항상 교체하므로 중복되지 않는다.

### 2. 원본 비변형
마이그레이션 후 기존 `requirements.txt`/`Pipfile`/poetry 설정을 자동 삭제하지 않는다. 검증은 사용자 몫으로 남기고 제거는 안내만 한다.

### 3. 추정 금지 — 검증으로 확인
"설치/마이그레이션 됐을 것"이라 가정하지 않는다. 각 단계 후 `uv --version`, `uv sync`, `uv run python --version`로 실제 결과를 확인한 뒤 다음으로 넘어간다.

### 4. conda는 자동 처리하지 않음
`environment.yml`(conda) 환경은 의존성 의미가 달라 자동 변환하지 않는다. 발견 시 사용자에게 보고하고 변환 방향을 함께 결정한다.

---

## 주의사항

- **워크트리에서 호출 시** — `.worktrees/` 안이면 규칙 문서가 워크트리 사본에만 기록된다. 메인 프로젝트 적용이 목적이면 사용자에게 확인할 것.
- **PATH 미반영** — uv 신규 설치 후 현재 셸에서 인식 안 되면 셸 재시작이 필요할 수 있음을 안내.
- **monorepo / 워크스페이스** — 여러 패키지가 있으면 `uv`의 workspace 기능(`[tool.uv.workspace]`)이 필요한지 사용자에게 확인.

---

## Source & Updates

Distributed from a git repository, not bundled with any project:

- Repository: https://github.com/zer0ken/skills (folder `claude/uv-setup/`)
- Installed copy: `~/.claude/skills/uv-setup/`

**Install or update (single file, no git or clone needed):**

PowerShell (Windows):
```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/claude/uv-setup/install.ps1 | iex
```
Bash (macOS / Linux / WSL):
```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/uv-setup/install.sh | bash
```
Re-running the command always fetches the latest `SKILL.md` — install and update are the
same command. (The installer refuses to overwrite a symlinked install dir, so a developer
working from a cloned repo is never clobbered.)

**Self-update check** (triggered by `uv-setup update`): do NOT run the setup. Diff the
canonical file against the installed copy and report:

```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/uv-setup/SKILL.md -o /tmp/uv-setup-remote.md
diff /tmp/uv-setup-remote.md "$HOME/.claude/skills/uv-setup/SKILL.md" \
  && echo "up to date" || echo "UPDATE AVAILABLE"
```
- No diff → tell the user the skill is already up to date.
- Diff present → show the one-line install command above and offer to run it. Updating
  overwrites `~/.claude/skills/uv-setup/SKILL.md`, so confirm with the user first.
