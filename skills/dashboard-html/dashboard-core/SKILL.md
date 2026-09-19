---
name: dashboard-core
version: v3.0.0
author: book-skills
description: 靜態 HTML 數據看板核心架構技能，掌握 RWD 版面規範、單頁/多頁靜態專案結構、圖表生命週期管理、前端狀態篩選與零依賴交付模式
---

# Dashboard Core (Static HTML Architecture)

## 任務目標
- 本 Skill 用於：搭建標準、專業、無後端依賴的**純靜態 HTML 數據看板架構**。
- 能力包含：專案結構設計（單檔自包含 vs 多頁工程化）、標準 RWD 看板佈局骨架、圖表實例生命週期管理器（自動 Resize / Tab 防破版）、純前端數據篩選聯動、無聯網/離線交付支援。
- 核心優勢：**客戶端瀏覽時，完全免安裝 pip、Python、Node.js 或 Streamlit**，雙擊 HTML 即可秒級開啟，兼具極致效能與極低維護成本。

---

## 專案結構模式

依據專案規模與交付情境，可選擇以下兩種結構：

### 模式 A：單檔自包含版 (Single-file HTML)
> **適用場景**：月度/季度分析報告、一次性數據交付、Email 附件發送、快速 Demo。
> **優勢**：只有單一 `.html` 檔案，透過 CDN 載入函式庫，任何電腦雙擊即可使用。

```
my-report/
└── dashboard.html       # 包含 HTML、Bootstrap、ECharts 與內嵌數據的單一檔案
```

### 模式 B：多頁模組化工程版 (Multi-page Static Web)
> **適用場景**：完整 BI 系統、公司內網數據看板、多個獨立主題分析頁面。

```
dashboard-project/
├── index.html           # 首頁 / 經營概覽
├── sales.html           # 銷售深入分析
├── users.html           # 客戶群體分析
├── assets/
│   ├── css/
│   │   ├── bootstrap.min.css    # (可選) 離線用 Bootstrap
│   │   └── dashboard.css        # 自訂樣式微調
│   ├── js/
│   │   ├── bootstrap.bundle.min.js # (可選) 離線用 Bootstrap JS
│   │   ├── echarts.min.js          # (可選) 離線用 ECharts
│   │   └── dashboard-core.js       # 圖表管理器與互動邏輯
│   └── data/
│       └── sales-data.json         # 外部靜態數據源 (可選)
```

---

## 核心看板 RWD 標準版面骨架

現代數據看板標準由「頂部導覽 + KPI 摘要行 + 主次圖表網格 + 詳細明細表」構成：

```html
<!DOCTYPE html>
<html lang="zh-Hant" data-bs-theme="light">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>營運數據儀表板</title>
  
  <!-- 1. Bootstrap 5.3 + Icons -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  
  <style>
    :root {
      --chart-height-sm: 280px;
      --chart-height-md: 360px;
    }
    .chart-container {
      width: 100%;
      height: var(--chart-height-md);
    }
  </style>
</head>
<body class="bg-body-tertiary">

  <!-- [導覽列] -->
  <nav class="navbar navbar-expand-lg bg-white border-bottom sticky-top">
    <div class="container-fluid px-4">
      <a class="navbar-brand fw-bold text-primary d-flex align-items-center gap-2" href="#">
        <i class="bi bi-graph-up-arrow"></i>
        <span>企業營運分析看板</span>
      </a>
      <span class="navbar-text small text-muted">
        數據更新時間：<span id="updateTime">2024-05-20</span>
      </span>
    </div>
  </nav>

  <!-- [主內容區] -->
  <main class="container-fluid px-4 py-4">

    <!-- 1. 頂部 4 格核心指標卡片 (KPI Row) -->
    <section class="row g-3 mb-4" id="kpiSection">
      <!-- 詳見 dashboard-bootstrap 技能規範 -->
    </section>

    <!-- 2. 全局篩選列 (Filter Row) -->
    <section class="card border-0 shadow-sm mb-4">
      <div class="card-body">
        <div class="row g-2 align-items-center">
          <div class="col-auto">
            <span class="fw-semibold small text-muted"><i class="bi bi-funnel me-1"></i>快速篩選：</span>
          </div>
          <div class="col-12 col-sm-auto">
            <select class="form-select form-select-sm" id="timePeriodSelect">
              <option value="today">今日即時</option>
              <option value="7d" selected>近 7 天</option>
              <option value="30d">近 30 天</option>
            </select>
          </div>
          <div class="col-12 col-sm-auto">
            <select class="form-select form-select-sm" id="regionSelect">
              <option value="all" selected>全區營運</option>
              <option value="north">北部</option>
              <option value="south">南部</option>
            </select>
          </div>
        </div>
      </div>
    </section>

    <!-- 3. 主次圖表網格 (Charts Grid) -->
    <section class="row g-3 mb-4">
      <!-- 左側 8 欄：主趨勢圖 (折線/面積) -->
      <div class="col-12 col-xl-8">
        <div class="card border-0 shadow-sm h-100">
          <div class="card-header bg-transparent border-0 pt-3">
            <h6 class="fw-bold mb-0">業績走勢分析</h6>
          </div>
          <div class="card-body">
            <div id="mainTrendChart" class="chart-container"></div>
          </div>
        </div>
      </div>

      <!-- 右側 4 欄：佔比圓餅圖 -->
      <div class="col-12 col-xl-4">
        <div class="card border-0 shadow-sm h-100">
          <div class="card-header bg-transparent border-0 pt-3">
            <h6 class="fw-bold mb-0">渠道來源佔比</h6>
          </div>
          <div class="card-body">
            <div id="channelPieChart" class="chart-container"></div>
          </div>
        </div>
      </div>
    </section>

    <!-- 4. 詳細數據表格 (Data Table) -->
    <section class="card border-0 shadow-sm mb-4">
      <div class="card-header bg-transparent border-0 pt-3">
        <h6 class="fw-bold mb-0">最新訂單明細</h6>
      </div>
      <div class="card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0" id="orderTable">
            <thead class="table-light">
              <tr>
                <th class="ps-4">訂單編號</th>
                <th>客戶</th>
                <th>金額</th>
                <th>狀態</th>
              </tr>
            </thead>
            <tbody>
              <!-- 數據列 -->
            </tbody>
          </table>
        </div>
      </div>
    </section>

  </main>

  <!-- 依賴載入 (Bootstrap + Apache ECharts) -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/echarts@5.5.0/dist/echarts.min.js"></script>
  
  <!-- 核心控制腳本 -->
  <script src="dashboard-core.js"></script>
</body>
</html>
```

---

## 圖表生命週期管理器 (Chart Lifecycle Orchestrator)

在多圖表看板中，必須由核心模組統一維護圖表實例，避免記憶體洩漏並解決螢幕縮放時的重繪問題：

```javascript
// dashboard-core.js
const DashboardApp = (function () {
  // 保存所有圖表實例
  const charts = new Map();

  // 1. 註冊並初始化圖表
  function registerChart(id, option) {
    const dom = document.getElementById(id);
    if (!dom) return null;

    const chartInstance = echarts.init(dom);
    chartInstance.setOption(option);
    charts.set(id, chartInstance);
    return chartInstance;
  }

  // 2. 取得圖表實例
  function getChart(id) {
    return charts.get(id);
  }

  // 3. 全局自適應縮放 (防抖處理)
  let resizeTimer = null;
  function handleResize() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
      charts.forEach(chart => {
        if (chart && !chart.isDisposed()) {
          chart.resize();
        }
      });
    }, 150);
  }

  // 4. 解決 Bootstrap 5 Tab 頁籤切換時寬度變 0 的問題
  function bindTabEvents() {
    document.querySelectorAll('button[data-bs-toggle="tab"], a[data-bs-toggle="tab"]').forEach(tab => {
      tab.addEventListener('shown.bs.tab', (event) => {
        const targetSelector = event.target.getAttribute('data-bs-target') || event.target.getAttribute('href');
        const targetContainer = document.querySelector(targetSelector);
        if (targetContainer) {
          targetContainer.querySelectorAll('.chart-container').forEach(el => {
            const chart = charts.get(el.id);
            if (chart) chart.resize();
          });
        }
      });
    });
  }

  // 5. 初始化全局監聽
  function init() {
    window.addEventListener('resize', handleResize);
    bindTabEvents();
  }

  return {
    init,
    registerChart,
    getChart,
    handleResize
  };
})();

// DOM 加載完成後啟動
document.addEventListener('DOMContentLoaded', () => {
  DashboardApp.init();
});
```

---

## 前端無依賴數據交互架構

在純靜態環境中，篩選器透過純 JavaScript 事件監聽動態過濾數據，並調用 `chart.setOption()`：

```javascript
// 模擬看板靜態數據庫
const DashboardData = {
  "7d": {
    trendDates: ['05-14', '05-15', '05-16', '05-17', '05-18', '05-19', '05-20'],
    trendRevenue: [3200, 4100, 3900, 5200, 6100, 7500, 8900],
    channelData: [
      { value: 540, name: '官網商城' },
      { value: 380, name: 'APP 下單' },
      { value: 210, name: '社群導購' }
    ]
  },
  "30d": {
    trendDates: ['W1', 'W2', 'W3', 'W4'],
    trendRevenue: [24000, 29000, 31000, 38000],
    channelData: [
      { value: 2400, name: '官網商城' },
      { value: 1650, name: 'APP 下單' },
      { value: 980, name: '社群導購' }
    ]
  }
};

// 篩選事件綁定
document.getElementById('timePeriodSelect').addEventListener('change', function (e) {
  const period = e.target.value;
  const currentData = DashboardData[period] || DashboardData['7d'];

  // 更新折線圖
  const trendChart = DashboardApp.getChart('mainTrendChart');
  if (trendChart) {
    trendChart.setOption({
      xAxis: { data: currentData.trendDates },
      series: [{ data: currentData.trendRevenue }]
    });
  }

  // 更新圓餅圖
  const pieChart = DashboardApp.getChart('channelPieChart');
  if (pieChart) {
    pieChart.setOption({
      series: [{ data: currentData.channelData }]
    });
  }
});
```

---

## 離線環境 (Air-Gapped) 交付指南

若客戶需要在完全無法存取外網的專網環境中瀏覽看板：
1. 將 `bootstrap.min.css`、`bootstrap.bundle.min.js` 與 `echarts.min.js` 下載至本機 `assets/` 目錄。
2. 將 HTML 內的 `<link>` 與 `<script>` 路徑改為相對路徑：
   ```html
   <link href="assets/css/bootstrap.min.css" rel="stylesheet">
   <script src="assets/js/bootstrap.bundle.min.js"></script>
   <script src="assets/js/echarts.min.js"></script>
   ```
3. 整個資料夾壓縮為 `.zip` 發送給客戶，解壓後雙擊 `index.html` 即可在離線電腦正常運作。
