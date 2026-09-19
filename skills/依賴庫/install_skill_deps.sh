#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# install_skill_deps.sh — 將本目錄的 wheel 套件離線安裝進 MindShub api 容器
#
# 背景:
#   - MindShub 技能腳本 (如 apache-parquet) 由 agent 在 **api 容器**內以
#     python3 執行，因此依賴必須裝進 api 容器的系統 Python。
#   - 本機與容器皆無外網連線，故使用離線 wheel (--no-index --find-links)。
#
# wheel 目錄結構:
#   依賴庫/3.12_arm64/*.whl    # cp312 + aarch64 wheels (Apple Silicon / M5 原生 docker)
#   依賴庫/3.12_x86_64/*.whl   # cp312 + x86_64 wheels (Intel Mac / amd64 容器)
#   依賴庫/3.10_x86_64/*.whl   # 舊版 cp310 wheels (不適用於目前容器，僅留檔)
#   未指定 --deps-dir 時會自動挑選與容器「Python 版本 + 架構」相符的 <主.次>_<arch> 子目錄。
#
# 用法:
#   ./install_skill_deps.sh                          # 自動偵測容器 + 對應版本的 wheels
#   ./install_skill_deps.sh --container mindshub-api-dev
#   ./install_skill_deps.sh --deps-dir /path/to/wheels
#
# ⚠️ wheel 的 Python 版本標籤 (cp3XX) 必須與容器內 Python 一致，
#    腳本會先做前置檢查；不符時給出重新下載指令。
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_DIR="$SCRIPT_DIR"
CONTAINER=""

usage() { grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deps-dir)
      DEPS_DIR="$2"
      shift 2
      ;;
    --container)
      CONTAINER="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "未知參數: $1 (使用 --help 查看用法)" >&2
      exit 1
      ;;
  esac
done

command -v docker >/dev/null 2>&1 || { echo "❌ 需要 docker CLI" >&2; exit 1; }

# ── 自動偵測 api 容器（dev 優先）────────────────────────────────────────────
if [[ -z "$CONTAINER" ]]; then
  for c in mindshub-api-dev mindshub-api; do
    if [[ "$(docker ps -q -f "name=^${c}$")" != "" ]]; then
      CONTAINER="$c"
      break
    fi
  done
fi
if [[ -z "$CONTAINER" ]]; then
  echo "❌ 找不到執行中的 api 容器 (mindshub-api-dev / mindshub-api)，可用 --container 指定" >&2
  exit 1
fi

# ── 取得容器 Python 版本（如 312）與架構（aarch64 / x86_64）──────────────
CONTAINER_PY="$(docker exec "$CONTAINER" python3 -c 'import sys; print(f"{sys.version_info[0]}{sys.version_info[1]}")')"
CONTAINER_ARCH="$(docker exec "$CONTAINER" uname -m)"   # aarch64 (M5/Apple Silicon) / x86_64

# ── 自動挑選與容器「版本 + 架構」相符的 wheel 子目錄（如 3.12_arm64）──────
if [[ "$DEPS_DIR" == "$SCRIPT_DIR" ]]; then
  VER_DIR="${CONTAINER_PY:0:1}.${CONTAINER_PY:1}"   # e.g. "3.12"
  case "$CONTAINER_ARCH" in
    aarch64|arm64) ARCH_DIR="arm64" ;;
    *)             ARCH_DIR="$CONTAINER_ARCH" ;;
  esac
  MATCHED="$(find "$SCRIPT_DIR" -maxdepth 1 -type d -name "${VER_DIR}_${ARCH_DIR}" | head -1)"
  # 找不到對應架構時退回任意同版本目錄（後續前置檢查會攔截不符的 wheel）
  [[ -z "$MATCHED" ]] && MATCHED="$(find "$SCRIPT_DIR" -maxdepth 1 -type d -name "${VER_DIR}_*" | head -1)"
  if [[ -n "$MATCHED" ]]; then
    DEPS_DIR="$MATCHED"
  fi
fi

# ── 檢查 wheels ──────────────────────────────────────────────────────────────
shopt -s nullglob
WHEELS=("$DEPS_DIR"/*.whl)
if [[ ${#WHEELS[@]} -eq 0 ]]; then
  echo "❌ $DEPS_DIR 內沒有 .whl 檔案（可用 --deps-dir 指定）" >&2
  exit 1
fi

# ── 前置檢查：wheel cp3XX 標籤 vs 容器 Python 版本、平台標籤 vs 容器架構 ────────
case "$CONTAINER_ARCH" in
  aarch64|arm64) ARCH_TOKEN='aarch64|arm64' ;;   # manylinux/musllinux 用 aarch64，macOS wheel 用 arm64
  *)             ARCH_TOKEN="$CONTAINER_ARCH" ;;  # x86_64 / amd64 ...
esac
BAD=()
for f in "${WHEELS[@]}"; do
  base="$(basename "$f")"
  tag="$(printf '%s' "$base" | grep -oE 'cp3[0-9]+' | head -1 || true)"
  if [[ -n "$tag" && "${tag#cp}" != "$CONTAINER_PY" ]]; then
    BAD+=("$base (需要 cp${tag#cp}，容器為 cp$CONTAINER_PY)")
  fi
  # 純 py wheel (*-none-any) 與架構無關，跳過；其餘檢查平台標籤是否含容器架構。
  # 平台標籤可能有多個（以 . 分隔，如 manylinux_2_17_aarch64.manylinux2014_aarch64），
  # 故直接檢查檔名中是否有「_<架構>」後接 . 或結尾的 token。
  if ! printf '%s' "$base" | grep -qE 'none-any\.whl$'; then
    if ! printf '%s' "$base" | grep -qE "_(${ARCH_TOKEN})(\.|$)"; then
      BAD+=("$base (平台不符，容器為 $CONTAINER_ARCH)")
    fi
  fi
done

if [[ ${#BAD[@]} -gt 0 ]]; then
  echo "❌ 以下 wheel 的 Python 版本與 api 容器 (cp$CONTAINER_PY) 不符：" >&2
  printf '   - %s\n' "${BAD[@]}" >&2
  cat >&2 <<EOF

   請在「有網路且為 Python ${CONTAINER_PY:0:1}.${CONTAINER_PY:1}」的機器上重新下載：
     pip download --only-binary=:all: -d "$DEPS_DIR" \\
       duckdb pyarrow pandas numpy openpyxl python-dateutil pytz six tzdata et-xmlfile
   跨架構下載（例如在 x86 機器為 arm64 容器備 wheel）：
     pip download --only-binary=:all: --platform manylinux2014_aarch64 \\
       -d "$DEPS_DIR" duckdb pyarrow pandas numpy openpyxl
   （純 py 套件如 six/tzdata 不需指定 platform；或直接用同架構的 python image：
     docker run --rm -v <目錄>:/wheels python:3.12-slim pip download --only-binary=:all: -d /wheels ...）
   然後重跑本腳本。
EOF
  exit 1
fi

echo "═══════════════════════════════════════════════════"
echo " 📦 技能依賴安裝 (離線 wheel)"
echo "═══════════════════════════════════════════════════"
echo "  Container:   $CONTAINER (Python cp$CONTAINER_PY)"
echo "  Wheels:      ${#WHEELS[@]} 個 @ $DEPS_DIR"
echo "═══════════════════════════════════════════════════"

STAGE="/tmp/skill-deps-$$"
docker exec "$CONTAINER" mkdir -p "$STAGE"
docker cp "$DEPS_DIR/." "${CONTAINER}:${STAGE}/"

# 容器內安裝（uv 優先，與 dev compose 的 uv pip install --system 一致）
docker exec "$CONTAINER" bash -c "
  set -e
  PKGS='duckdb pyarrow pandas openpyxl'
  if command -v uv >/dev/null 2>&1; then
    uv pip install --system --no-index --find-links $STAGE \$PKGS
  else
    python3 -m pip install --no-index --find-links $STAGE \$PKGS
  fi
  rm -rf $STAGE
"

# ── 驗證 import ──────────────────────────────────────────────────────────────
echo ""
echo "⏳ 驗證 import..."
docker exec "$CONTAINER" python3 -c "import duckdb, pyarrow, pandas, openpyxl; print('   ✅ duckdb  ', duckdb.__version__); print('   ✅ pyarrow ', pyarrow.__version__); print('   ✅ pandas  ', pandas.__version__); print('   ✅ openpyxl', openpyxl.__version__)"

echo ""
echo "✅ 技能依賴已安裝進 $CONTAINER。"
echo "   ⚠️ 容器重建 (docker compose up -d --force-recreate) 後會遺失，需重跑本腳本；"
echo "      若要永久保留，請將 wheel COPY 進 Dockerfile.api.dev 於 build 時安裝。"
