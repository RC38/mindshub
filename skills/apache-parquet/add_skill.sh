#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# add_skill.sh — 將本目錄的 SKILL.md 自動註冊到 MindShub 技能庫 (Web UI)
#
# 用法:
#   ./add_skill.sh                          # 使用預設 API 位址 (localhost:26866)
#   ./add_skill.sh --api http://host:port   # 指定 API 位址
#   ./add_skill.sh --skill /path/to/SKILL.md  # 指定其他 SKILL.md 路徑
#
# 行為:
#   - 解析 SKILL.md 的 YAML frontmatter (name, display_name, description)
#     * name        → label / identifier（唯一鍵，勿改）
#     * display_name→ Web UI 列表顯示名稱（選填，預設同 name）
#   - 以 markdown body 作為 declarative (技能指令)
#   - 若存在「觸發場景」章節，提取為 whenToUse
#   - POST /api/v1/skills/ 註冊技能
#   - 若 label 已存在則回報並提示手動處理（不覆蓋）
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── 預設值 ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="${SCRIPT_DIR}/SKILL.md"
API_BASE="http://localhost:26866/api/v1"

# ── 參數解析 ──────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --api)
      API_BASE="$2"
      shift 2
      ;;
    --skill)
      SKILL_FILE="$2"
      shift 2
      ;;
    -h|--help)
      grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "未知參數: $1 (使用 --help 查看用法)" >&2
      exit 1
      ;;
  esac
done

# ── 前置檢查 ──────────────────────────────────────────────────────────────────
if [[ ! -f "$SKILL_FILE" ]]; then
  echo "❌ 找不到 SKILL.md: $SKILL_FILE" >&2
  exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "❌ 需要 curl" >&2; exit 1; }

# ── 解析 YAML frontmatter ────────────────────────────────────────────────────
# 提取兩個 --- 之間的內容
FRONTMATTER=$(awk '/^---$/{count++; next} count==1{print} count>=2{exit}' "$SKILL_FILE")

# 從 frontmatter 取值（支援單行 key: value）
fm_get() {
  local key="$1"
  printf '%s\n' "$FRONTMATTER" | grep -E "^${key}:" | head -1 | sed "s/^${key}:[[:space:]]*//" | sed 's/[[:space:]]*$//'
}

LABEL=$(fm_get "name")
DISPLAY_NAME=$(fm_get "display_name")   # Web UI 顯示名稱，選填
DESCRIPTION=$(fm_get "description")

if [[ -z "$LABEL" ]]; then
  echo "❌ SKILL.md frontmatter 缺少 name 欄位（將用作 label）" >&2
  exit 1
fi
# 未指定 display_name 時，顯示名稱同 label
[[ -n "$DISPLAY_NAME" ]] || DISPLAY_NAME="$LABEL"

# ── 提取 markdown body (frontmatter 之後的全部內容) ─────────────────────────
BODY=$(awk '/^---$/{count++; next} count>=2{print}' "$SKILL_FILE")

if [[ -z "$BODY" ]]; then
  echo "❌ SKILL.md 沒有 frontmatter 之後的 markdown 內容" >&2
  exit 1
fi

# ── 提取「觸發場景」章節作為 whenToUse（選填）──────────────────────────────
WHEN_TO_USE=""
if printf '%s\n' "$BODY" | grep -q '## 觸發場景'; then
  WHEN_TO_USE=$(printf '%s\n' "$BODY" \
    | awk '/^## 觸發場景/{found=1; next} found && /^## /{exit} found{print}' \
    | sed '/^[[:space:]]*$/d')
fi

# ── 顯示將要提交的內容 ───────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════"
echo " 📦 技能註冊"
echo "═══════════════════════════════════════════════════"
echo "  Label:       $LABEL"
echo "  Name:        $DISPLAY_NAME (顯示名稱)"
echo "  Description: ${DESCRIPTION:0:60}..."
if [[ -n "$WHEN_TO_USE" ]]; then
  echo "  WhenToUse:   (已從「觸發場景」章節提取, $(printf '%s' "$WHEN_TO_USE" | wc -l) 行)"
fi
echo "  Instructions: $(printf '%s' "$BODY" | wc -c) bytes"
echo "  API:         $API_BASE/skills/"
echo "═══════════════════════════════════════════════════"

# ── 確認（非互動環境自動繼續）───────────────────────────────────────────────
if [[ -t 0 ]]; then
  read -rp "確認註冊? [Y/n] " CONFIRM
  case "$CONFIRM" in
    [nN]*) echo "已取消。"; exit 0 ;;
  esac
fi

# ── 組裝 JSON payload（使用 python3 確保正確轉義）──────────────────────────
PAYLOAD=$(python3 -c "
import json, sys

label = sys.argv[1]
display_name = sys.argv[2]
description = sys.argv[3]
when_to_use = sys.argv[4]
body = open(sys.argv[5], 'r', encoding='utf-8').read()

# 重新提取 body (frontmatter 之後)
lines = body.split('\n')
count = 0
start = None
for i, line in enumerate(lines):
    if line.strip() == '---':
        count += 1
        if count == 2:
            start = i + 1
            break
md_body = '\n'.join(lines[start:]) if start else ''

payload = {
    'label': label,
    'name': display_name or label,
    'description': description or None,
    'whenToUse': when_to_use or None,
    'declarative': md_body,
}
print(json.dumps(payload, ensure_ascii=False))
" "$LABEL" "$DISPLAY_NAME" "$DESCRIPTION" "$WHEN_TO_USE" "$SKILL_FILE")

# ── 先檢查是否已存在（GET list）──────────────────────────────────────────────
echo ""
echo "⏳ 查詢現有技能..."
EXISTING=$(curl -sf "${API_BASE}/skills/" 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    skills = data.get('skills', [])
    for s in skills:
        if s.get('label') == '$LABEL':
            print(s['id'])
            break
except Exception:
    pass
" 2>/dev/null || true)

if [[ -n "$EXISTING" ]]; then
  echo "⚠️  Label '$LABEL' 已存在 (ID: $EXISTING)"
  echo "   如需更新，請使用 PUT /api/v1/skills/$EXISTING"
  echo "   或先在 Web UI 刪除後再執行此腳本。"
  exit 0
fi

# ── POST 註冊 ────────────────────────────────────────────────────────────────
echo "⏳ 正在註冊技能..."
RESPONSE=$(curl -s -w '\n%{http_code}' -X POST "${API_BASE}/skills/" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD")

HTTP_CODE=$(printf '%s' "$RESPONSE" | tail -1)
BODY_RESP=$(printf '%s' "$RESPONSE" | sed '$d')

case "$HTTP_CODE" in
  201)
    echo ""
    echo "✅ 技能註冊成功！"
    printf '%s\n' "$BODY_RESP" | python3 -m json.tool 2>/dev/null || printf '%s\n' "$BODY_RESP"
    echo ""
    echo "   請到 Web UI (http://localhost:15173) → 技能庫 確認。"

    # ── 複製技能目錄進 api 容器（讓 agent 可讀取子檔案）──────────────────
    SKILL_CONTAINER_PATH="/root/.cowork/anton/skills/${LABEL}"
    API_CONTAINER=""
    for c in mindshub-api-dev mindshub-api; do
      if [[ "$(docker ps -q -f "name=^${c}$")" != "" ]]; then
        API_CONTAINER="$c"
        break
      fi
    done
    if [[ -n "$API_CONTAINER" ]]; then
      echo ""
      echo "📂 複製技能檔案進容器 (${API_CONTAINER})..."
      docker cp "${SCRIPT_DIR}/." "${API_CONTAINER}:${SKILL_CONTAINER_PATH}" && \
        echo "   ✅ 已複製至 ${SKILL_CONTAINER_PATH}/ (含 references/、skills/ 等子目錄)" || \
        { echo "   ⚠️  複製失敗，請手動執行:" >&2; \
          echo "      docker cp ${SCRIPT_DIR}/. ${API_CONTAINER}:${SKILL_CONTAINER_PATH}" >&2; }
    else
      echo ""
      echo "ℹ️  未找到 api 容器 (mindshub-api-dev / mindshub-api)，跳過技能檔案複製。"
    fi

    # ── 一併安裝技能依賴進 api 容器（離線 wheel）──────────────────────────
    DEPS_INSTALLER="${SCRIPT_DIR}/../依賴庫/install_skill_deps.sh"
    if [[ -x "$DEPS_INSTALLER" ]]; then
      echo ""
      echo "🔧 開始將技能依賴安裝進 api 容器..."
      bash "$DEPS_INSTALLER" || {
        echo "⚠️  依賴安裝失敗，請手動執行: $DEPS_INSTALLER" >&2
        exit 1
      }
    else
      echo ""
      echo "ℹ️  未找到依賴安裝腳本 ($DEPS_INSTALLER)，跳過容器內依賴安裝。"
    fi
    ;;
  409)
    echo ""
    echo "⚠️  技能已存在（label 或 name 衝突）:"
    printf '%s\n' "$BODY_RESP"
    exit 0
    ;;
  *)
    echo ""
    echo "❌ 註冊失敗 (HTTP $HTTP_CODE):"
    printf '%s\n' "$BODY_RESP"
    exit 1
    ;;
esac
