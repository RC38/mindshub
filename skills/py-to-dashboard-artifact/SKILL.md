---
name: py-to-dashboard-artifact
display_name: Python 分析 → HTML 儀表板（自動進入產出區塊）
version: v1.0.0
author: book-skills
description: 上傳 .py 或要求 Python 資料分析並產出儀表板/報表時使用：先 create_artifact(type=html-app) 註冊，再把自包含 HTML 寫入回傳路徑，讓產出出現在專案右側「產出」區塊。
---

# Python 分析 → HTML 儀表板（自動進入產出區塊）

## 觸發場景

- 使用者上傳 `.py` 檔（分析腳本、資料處理程式）。
- 要求以 Python / pandas 分析資料並產生儀表板或報表。
- 提到要把分析結果做成看板、dashboard、HTML 報告時。

---

## 任務目標

使用者上傳 `.py` 檔（或要求以 Python 分析資料）並需要儀表板/報表時，產出**單一自包含 HTML dashboard**，並透過 `create_artifact` 註冊到專案「產出」區塊（右側 rail），讓使用者可直接在 MindShub 內預覽。

---

## 標準流程（依序執行）

1. **讀取上傳的 .py**：用 scratchpad 讀檔理解其邏輯與資料來源；不要直接 `exec`/`subprocess` 執行上傳腳本（環境、相依套件不可控）。以 scratchpad 重寫或引用其核心邏輯。
2. **先呼叫 `create_artifact`**（在寫任何輸出檔案之前）：
   - `type="html-app"`，`primary="dashboard.html"`
   - `name`/`description` 用中文描述儀表板內容
   - tool 回傳 `{slug, path}` — 之後所有產出檔都寫入這個 `path`。
3. **取數 + 計算**：scratchpad 內完成資料擷取與指標計算（pandas 等），先 print 關鍵數字確認合理。
4. **產生 HTML**：將資料、CSS、JS **全部 inline** 進單一 `dashboard.html`，寫入 `<artifact_path>/dashboard.html`。
   - 圖表建議 Apache ECharts（CDN 或內嵌）；版面可用 Bootstrap 5 CDN。
   - 可先 `recall_skill("dashboard-html")` 取得看板架構/圖表範本再動手。
   - **禁止**引用外部本地檔（如 data.js、./chart.png）— file:// 與預覽 iframe 都會被瀏覽器擋掉，儀表板會靜默空白。
5. **收尾驗證**：若入口檔名有變，呼叫 `update_artifact(slug, primary=...)`；確認檔案已寫入且大小合理（>10KB 通常代表圖表資料已內嵌）。

---

## 關鍵慣例（踩過的坑）

- **未呼叫 `create_artifact` 的檔案不會出現在「產出」區塊** — 只有 `<project>/.anton/artifacts/<slug>/metadata.json` 存在的資料夾會被掃描。先註冊、再寫檔，順序不可反。
- 修改既有 dashboard：用 `list_artifacts()` + `open_artifact(slug)` 拿回 path，**不要重複 create_artifact**（會產生重複卡片）。
- 純 chat 內的表格/文字回覆不算 artifact，不需要註冊；只有「要存檔給使用者開啟」的產出才需要。
