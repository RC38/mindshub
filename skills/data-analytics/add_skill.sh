#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# add_skill.sh — Data Analytics 項目技能庫自動化註冊與部署腳本
#
# 功能:
#   1. 自動掃描並註冊 Data Analytics 體系技能：
#      - 根目錄主技能 (data-analytics)：數據分析師全能力體系導航與入口
#      - 所有子目錄技能 (analytics-core, analytics-data-processing, ...)
#   2. 支援冪等部署 (Upsert)：
#      - 若技能不存在 → 自動執行 POST /api/v1/skills/ 註冊 (HTTP 201)
#      - 若技能已存在 → 自動執行 PUT /api/v1/skills/{id} 更新 (HTTP 200)
#   3. 智能解析元數據 (YAML frontmatter + Markdown 正文):
#      - label / name: 唯一識別碼 (name)
#      - display_name: Web UI 列表顯示名稱（優先讀取 display_name，次取 H1 標題）
#      - description: 技能功能描述
#      - whenToUse: 智能提取「適用場景 / 觸發場景 / 觸發條件」
#      - declarative: 完整 Markdown 執行手冊
#   4. 同步複製技能目錄進 MindShub API 容器 (/root/.cowork/anton/skills/)
#      並在容器內為各子技能建立軟連結，保證 Agent 與 Tool 讀取無誤。
#   5. 自動安裝技能離線 Python 依賴 (若依賴庫存在)。
#
# 用法:
#   ./add_skill.sh                          # 預設部署全部（主技能 + 6 個子技能，支援自動更新）
#   ./add_skill.sh --root-only              # 僅部署根目錄主技能 (data-analytics)
#   ./add_skill.sh --skill <path/to/SKILL>  # 僅部署指定 SKILL.md
#   ./add_skill.sh --api http://host:port   # 指定 API 位址 (預設 http://localhost:26866/api/v1)
#   ./add_skill.sh --dry-run                # 僅預覽待提交資料，不發送請求或修改容器
#   ./add_skill.sh --no-deps                # 跳過 Python 離線依賴安裝
#   ./add_skill.sh --no-update              # 若技能已存在則跳過，不更新
#   ./add_skill.sh -y, --yes                # 自動確認（免互動提示）
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── 預設設定 ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_BASE="http://localhost:26866/api/v1"
SPECIFIC_SKILL=""
ROOT_ONLY=0
AUTO_UPDATE=1
COPY_CONTAINER=1
INSTALL_DEPS=1
DRY_RUN=0
ASSUME_YES=0

# ── 參數解析 ──────────────────────────────────────────────────────────────────
usage() {
  grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api)
      API_BASE="$2"
      shift 2
      ;;
    --skill)
      SPECIFIC_SKILL="$2"
      shift 2
      ;;
    --root-only)
      ROOT_ONLY=1
      shift
      ;;
    --no-update)
      AUTO_UPDATE=0
      shift
      ;;
    --no-copy)
      COPY_CONTAINER=0
      shift
      ;;
    --no-deps)
      INSTALL_DEPS=0
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -y|--yes)
      ASSUME_YES=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "❌ 未知參數: $1 (使用 --help 查看用法)" >&2
      exit 1
      ;;
  esac
done

command -v curl >/dev/null 2>&1 || { echo "❌ 缺少必要工具: curl" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ 缺少必要工具: python3" >&2; exit 1; }

# ── 收集待處理的 SKILL.md 列表 ────────────────────────────────────────────────
SKILL_FILES=()

if [[ -n "$SPECIFIC_SKILL" ]]; then
  if [[ ! -f "$SPECIFIC_SKILL" ]]; then
    echo "❌ 找不到指定的技能檔案: $SPECIFIC_SKILL" >&2
    exit 1
  fi
  SKILL_FILES+=("$SPECIFIC_SKILL")
elif [[ "$ROOT_ONLY" -eq 1 ]]; then
  SKILL_FILES+=("${SCRIPT_DIR}/SKILL.md")
else
  # 預設：根目錄主技能 + 所有一級子目錄下的 SKILL.md
  if [[ -f "${SCRIPT_DIR}/SKILL.md" ]]; then
    SKILL_FILES+=("${SCRIPT_DIR}/SKILL.md")
  fi
  while IFS= read -r f; do
    [[ -n "$f" ]] && SKILL_FILES+=("$f")
  done < <(find "${SCRIPT_DIR}" -mindepth 2 -maxdepth 2 -type f -name "SKILL.md" | sort)
fi

if [[ ${#SKILL_FILES[@]} -eq 0 ]]; then
  echo "❌ 未找到任何 SKILL.md 檔案" >&2
  exit 1
fi

echo "═══════════════════════════════════════════════════════════════════════════"
echo " 📊 Data Analytics 項目技能庫部署"
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  目標 API:       $API_BASE"
echo "  待處理技能數:   ${#SKILL_FILES[@]} 個"
echo "  自動更新(PUT):  $([[ $AUTO_UPDATE -eq 1 ]] && echo '啟用' || echo '停用')"
echo "  同步容器檔案:   $([[ $COPY_CONTAINER -eq 1 ]] && echo '啟用' || echo '停用')"
echo "  安裝離線依賴:   $([[ $INSTALL_DEPS -eq 1 ]] && echo '啟用' || echo '停用')"
echo "  乾跑模式(Dry):  $([[ $DRY_RUN -eq 1 ]] && echo '是' || echo '否')"
echo "───────────────────────────────────────────────────────────────────────────"
for sf in "${SKILL_FILES[@]}"; do
  rel_path="${sf#"${SCRIPT_DIR}/"}"
  [[ "$rel_path" == "$sf" ]] && rel_path="$(basename "$sf")"
  echo "  • $rel_path"
done
echo "═══════════════════════════════════════════════════════════════════════════"

# ── 互動確認 ──────────────────────────────────────────────────────────────────
if [[ "$ASSUME_YES" -eq 0 && -t 0 && "$DRY_RUN" -eq 0 ]]; then
  read -rp "確認執行部署? [Y/n] " CONFIRM
  case "$CONFIRM" in
    [nN]*) echo "已取消部署。"; exit 0 ;;
  esac
fi

# ── 執行 Python 批次解析與註冊 ────────────────────────────────────────────────
echo ""
echo "🚀 開始解析並註冊技能至 MindShub API..."

export API_BASE AUTO_UPDATE DRY_RUN
python3 - << 'PYEOF' "${SKILL_FILES[@]}"
import os, sys, json, re, urllib.request, urllib.error

api_base = os.environ.get("API_BASE", "http://localhost:26866/api/v1").rstrip("/")
auto_update = os.environ.get("AUTO_UPDATE", "1") == "1"
dry_run = os.environ.get("DRY_RUN", "0") == "1"
skill_files = sys.argv[1:]

def fetch_json(url, method="GET", data=None):
    headers = {"Accept": "application/json"}
    body = None
    if data is not None:
        headers["Content-Type"] = "application/json"
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            code = resp.status
            content = resp.read().decode("utf-8")
            return code, json.loads(content) if content else {}
    except urllib.error.HTTPError as e:
        err_content = e.read().decode("utf-8")
        try:
            err_json = json.loads(err_content)
        except Exception:
            err_json = {"detail": err_content}
        return e.code, err_json
    except Exception as e:
        return 0, {"error": str(e)}

# 1. 查詢現有技能清單
existing_skills = {}
if not dry_run:
    code, res = fetch_json(f"{api_base}/skills/")
    if code != 200:
        print(f"❌ 無法連接 API 或獲取技能列表 (HTTP {code}): {res}")
        sys.exit(1)
    for item in res.get("skills", []):
        if "label" in item and "id" in item:
            existing_skills[item["label"]] = item["id"]

# 2. 依序解析各個 SKILL.md
results = []
for sf in skill_files:
    try:
        raw = open(sf, "r", encoding="utf-8").read()
    except Exception as e:
        print(f"❌ 讀取檔案失敗 {sf}: {e}")
        continue

    parts = raw.split("---", 2)
    fm_str = parts[1] if len(parts) >= 3 else ""
    body_str = parts[2] if len(parts) >= 3 else raw

    # 解析 frontmatter
    fm = {}
    for line in fm_str.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"^([a-zA-Z0-9_-]+)\s*:\s*(.*)$", line)
        if m:
            k, v = m.group(1), m.group(2).strip()
            # 移除外層引號
            if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
                v = v[1:-1]
            fm[k] = v

    label = fm.get("name", "").strip()
    if not label:
        print(f"⚠️  跳過 {sf}: frontmatter 中未設定 name (label)")
        continue

    # 提取顯示名稱 display_name
    display_name = fm.get("display_name", "").strip()
    if not display_name:
        h1_match = re.search(r"^#\s+(.+)$", body_str, re.MULTILINE)
        if h1_match:
            display_name = h1_match.group(1).strip()
        else:
            display_name = label

    # 提取 description
    description = fm.get("description", "").strip()

    # 提取 whenToUse（適用場景 / 觸發條件）
    when_to_use = ""
    # 策略 A: 找 ## 適用場景 / ## 觸發場景 / ## 觸發條件
    scene_match = re.search(r"##\s+(?:適用場景|觸發場景|觸發條件)([\s\S]*?)(?=\n##|\Z)", body_str)
    if scene_match:
        lines = [l.strip() for l in scene_match.group(1).splitlines() if l.strip().startswith(("-", "*", "1.", "2.", "3.", "4.", "5."))]
        if lines:
            when_to_use = "\n".join(lines)
    # 策略 B: 若仍無，搜尋段落中的「觸發條件：」
    if not when_to_use:
        cond_match = re.search(r"觸發條件[：:]([^\n]+)", body_str)
        if cond_match:
            when_to_use = f"- {cond_match.group(1).strip()}"
    # 策略 C: 若主技能有快速選型速查表，提取問題清單
    if label == "data-analytics" and "## 快速選型速查表" in body_str:
        tbl_match = re.search(r"##\s+快速選型速查表([\s\S]*?)(?=\n##|\Z)", body_str)
        if tbl_match:
            qs = re.findall(r"\|\s*「?([^|]+?)」?\s*\|\s*`?[a-zA-Z0-9_-]+`?\s*\|", tbl_match.group(1))
            extracted_qs = [f"- 「{q.strip()}」" for q in qs if not q.strip().startswith("使用者問題")]
            if extracted_qs:
                base_scene = when_to_use.splitlines() if when_to_use else []
                when_to_use = "\n".join(base_scene + extracted_qs)

    payload = {
        "label": label,
        "name": display_name,
        "description": description or None,
        "whenToUse": when_to_use or None,
        "declarative": body_str.strip(),
    }

    exist_id = existing_skills.get(label)
    status_label = ""
    status_icon = ""

    if dry_run:
        status_icon = "🔍"
        status_label = f"[DRY-RUN] ({'已存在, 將更新' if exist_id else '新技能, 將創建'})"
        results.append((status_icon, label, display_name, status_label))
        continue

    if exist_id:
        if not auto_update:
            status_icon = "⏭️"
            status_label = f"已存在 (ID: {exist_id[:8]}...), 略過更新"
            results.append((status_icon, label, display_name, status_label))
            continue
        # 執行 PUT 更新
        code, resp = fetch_json(f"{api_base}/skills/{exist_id}", method="PUT", data=payload)
        if code in (200, 201):
            status_icon = "🔄"
            status_label = f"更新成功 (ID: {exist_id[:8]}...)"
        else:
            status_icon = "❌"
            status_label = f"更新失敗 (HTTP {code}): {resp}"
    else:
        # 執行 POST 建立
        code, resp = fetch_json(f"{api_base}/skills/", method="POST", data=payload)
        if code == 201:
            new_id = resp.get("id", "")
            status_icon = "✨"
            status_label = f"註冊成功 (ID: {new_id[:8]}...)"
            existing_skills[label] = new_id
        elif code == 409:
            status_icon = "⚠️"
            status_label = "衝突已存在"
        else:
            status_icon = "❌"
            status_label = f"註冊失敗 (HTTP {code}): {resp}"

    results.append((status_icon, label, display_name, status_label))

print("\n" + "─" * 75)
print(" 📋 技能註冊與更新結果報告:")
print("─" * 75)
for icon, lbl, dname, st in results:
    print(f" {icon} [{lbl:<26}] {dname:<30} ➔ {st}")
print("─" * 75)

# 若有失敗則退出非零碼
if any(r[0] == "❌" for r in results):
    sys.exit(1)
PYEOF

# ── 同步技能目錄進 API 容器 ──────────────────────────────────────────────────
if [[ "$COPY_CONTAINER" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
  API_CONTAINER=""
  for c in mindshub-api-dev mindshub-api; do
    if [[ "$(docker ps -q -f "name=^${c}$")" != "" ]]; then
      API_CONTAINER="$c"
      break
    fi
  done

  if [[ -n "$API_CONTAINER" ]]; then
    echo ""
    echo "📂 正在同步技能目錄進 API 容器 (${API_CONTAINER})..."
    SKILLS_BASE_IN_CONTAINER="/root/.cowork/anton/skills"
    TARGET_CONTAINER_DIR="${SKILLS_BASE_IN_CONTAINER}/data-analytics"

    # 確保容器內目標目錄存在
    docker exec "$API_CONTAINER" mkdir -p "$TARGET_CONTAINER_DIR"

    # 複製本專案目錄完整檔案進容器
    docker cp "${SCRIPT_DIR}/." "${API_CONTAINER}:${TARGET_CONTAINER_DIR}/"
    echo "   ✅ 已同步主目錄至 ${TARGET_CONTAINER_DIR}/"

    # 為各子技能建立符號連結（symlink），讓 agent 可透過 /root/.cowork/anton/skills/<子技能名> 直接存取
    echo "🔗 正在為子技能建立符號連結 (Symlinks)..."
    for sf in "${SKILL_FILES[@]}"; do
      sub_dir="$(dirname "$sf")"
      sub_name="$(basename "$sub_dir")"
      if [[ "$sub_dir" != "$SCRIPT_DIR" && -n "$sub_name" ]]; then
        docker exec "$API_CONTAINER" sh -c "ln -sfn '${TARGET_CONTAINER_DIR}/${sub_name}' '${SKILLS_BASE_IN_CONTAINER}/${sub_name}'"
        echo "   • ${SKILLS_BASE_IN_CONTAINER}/${sub_name} ➔ ${TARGET_CONTAINER_DIR}/${sub_name}"
      fi
    done
    echo "   ✅ 符號連結建立完成！"
  else
    echo ""
    echo "ℹ️  未找到執行中的 API 容器 (mindshub-api-dev / mindshub-api)，跳過容器檔案複製。"
  fi
fi

# ── 安裝技能離線依賴 ─────────────────────────────────────────────────────────
if [[ "$INSTALL_DEPS" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
  DEPS_INSTALLER="${SCRIPT_DIR}/../依賴庫/install_skill_deps.sh"
  if [[ -x "$DEPS_INSTALLER" ]]; then
    echo ""
    echo "🔧 執行依賴安裝 (install_skill_deps.sh)..."
    bash "$DEPS_INSTALLER" || {
      echo "⚠️  依賴安裝未完全成功，但技能註冊已完成。" >&2
    }
  else
    echo ""
    echo "ℹ️  未找到或不可執行依賴安裝腳本 ($DEPS_INSTALLER)，跳過依賴安裝。"
  fi
fi

echo ""
echo "🎉 部署完成！"
echo "👉 請至 MindShub Web UI (http://localhost:15173/#/skills 或側邊欄「技能庫」) 檢視與啟用。"
