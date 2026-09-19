---
name: dashboard-html
version: v1.0.0
author: book-skills
description: 靜態 HTML 數據儀表板技能庫，使用 Bootstrap 5 (RWD) + Apache ECharts 快速建構自適應響應式數據看板，客戶端免裝 Python/pip/Streamlit，瀏覽器秒開
---

# Dashboard HTML (Bootstrap 5 + Apache ECharts)

## 任務目標

- 本 Skill 用於：快速建構高品質、現代化、**純靜態 HTML 響應式數據儀表板**。
- 能力包含：Bootstrap 5 RWD 網格佈局、KPI 指標摘要卡片、Apache ECharts 互動圖表視覺化、圖表自適應縮放（Resize）、純前端數據篩選、零依賴交付。
- 觸發條件：需要建立數據分析與視覺化看板，且**要求客戶端瀏覽時免安裝 Python、pip、Node.js 或 Streamlit** 時。

---

## 核心特性

| 特性 | 說明 |
| :--- | :--- |
| 🚀 **客戶端零依賴** | 使用標準 HTML5 + CSS3 + JS，任何現代瀏覽器（Chrome, Edge, Safari, Firefox）雙擊即可直接瀏覽。 |
| 📱 **完全響應式 (RWD)** | 基於 Bootstrap 5.3 網格系統，手機、平板、桌面端全自適應佈局。 |
| 📊 **豐富互動視覺化** | 採用 Apache ECharts 5 原生圖表（折線、柱狀、圓餅、雷達、儀表盤等），支援 Tooltip、圖例切換與動畫。 |
| 🔄 **無破版 Resize 機制** | 內建全域防抖 Resize 監聽與 Tab 切換適配，解決視窗縮放與隱藏容器寬度塌陷問題。 |
| 📦 **交付靈活** | 支援單一 `.html` 檔案快速交付、CDN 線上載入或全離線內網運行模式。 |

---

## 技能地圖

### 基礎與架構
- [dashboard-core](dashboard-core/) - **靜態看板架構**：單頁/多頁專案結構、看板版面規範、圖表生命週期管理、Tab 切換防破版、純前端篩選互動。
- [dashboard-bootstrap](dashboard-bootstrap/) - **Bootstrap 5 RWD 框架**：網格系統、KPI 摘要卡片、頂部導覽列/側邊抽屜、圖表容器、響應式表格、深色模式切換。

### 圖表與數據
- [dashboard-echarts](dashboard-echarts/) - **Apache ECharts 看板整合**：原生 JS 圖表配置、漸層折線圖、堆疊柱狀圖、環形圖、儀表盤、自訂 Tooltip 與 Bootstrap 容器自適應縮放。
- [dashboard-pandas](dashboard-pandas/) - **離線數據前處理 (可選)**：在開發端使用 Python/Pandas 清洗數據並導出為 ECharts JSON 格式（客戶端免裝 Python）。

### 進階專業圖表庫 (外部協同)
- [tool/echart](../echart/) - **Apache ECharts 全技能族 (百科級)**：當看板需要桑基圖、關係圖、統計熱力圖、地理地圖、3D 視覺化、金融 K 線或多圖深度連動時，調用此專門技能族（收錄 8 大子技能與 365+ 官方精選範例）。

---

## 快速開始：完整單頁儀表板範本

將以下程式碼儲存為 `index.html`，直接雙擊即可在瀏覽器中開啟運行：

```html
<!DOCTYPE html>
<html lang="zh-Hant" data-bs-theme="light">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>營運數據分析儀表板</title>
  
  <!-- Bootstrap 5.3 CSS -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <!-- Bootstrap Icons -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  
  <style>
    body { background-color: #f8f9fa; }
    .chart-box { width: 100%; height: 350px; }
  </style>
</head>
<body>

  <!-- 頂部導覽列 -->
  <nav class="navbar navbar-expand-lg bg-white border-bottom sticky-top">
    <div class="container-fluid px-4">
      <a class="navbar-brand fw-bold text-primary d-flex align-items-center gap-2" href="#">
        <i class="bi bi-speedometer2 fs-4"></i>
        <span>企業營運分析看板</span>
      </a>
      <span class="badge bg-success-subtle text-success">系統運作正常</span>
    </div>
  </nav>

  <!-- 主內容容器 -->
  <main class="container-fluid px-4 py-4">

    <!-- 1. 頂部 KPI 指標卡片 -->
    <div class="row g-3 mb-4">
      <div class="col-12 col-sm-6 col-xl-3">
        <div class="card border-0 shadow-sm border-start border-primary border-4 h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-1">
              <span class="text-muted small fw-semibold">總營收</span>
              <i class="bi bi-currency-dollar text-primary fs-5"></i>
            </div>
            <h3 class="fw-bold mb-1">NT$ 3,842,500</h3>
            <span class="badge bg-success-subtle text-success"><i class="bi bi-arrow-up"></i> +14.2%</span>
            <span class="text-muted small">較上月</span>
          </div>
        </div>
      </div>

      <div class="col-12 col-sm-6 col-xl-3">
        <div class="card border-0 shadow-sm border-start border-success border-4 h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-1">
              <span class="text-muted small fw-semibold">訂單總量</span>
              <i class="bi bi-bag-check text-success fs-5"></i>
            </div>
            <h3 class="fw-bold mb-1">8,420 筆</h3>
            <span class="badge bg-success-subtle text-success"><i class="bi bi-arrow-up"></i> +9.5%</span>
            <span class="text-muted small">達標率 108%</span>
          </div>
        </div>
      </div>

      <div class="col-12 col-sm-6 col-xl-3">
        <div class="card border-0 shadow-sm border-start border-info border-4 h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-1">
              <span class="text-muted small fw-semibold">活躍會員</span>
              <i class="bi bi-people text-info fs-5"></i>
            </div>
            <h3 class="fw-bold mb-1">52,180 人</h3>
            <span class="badge bg-danger-subtle text-danger"><i class="bi bi-arrow-down"></i> -1.2%</span>
            <span class="text-muted small">日活躍率 62%</span>
          </div>
        </div>
      </div>

      <div class="col-12 col-sm-6 col-xl-3">
        <div class="card border-0 shadow-sm border-start border-warning border-4 h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-1">
              <span class="text-muted small fw-semibold">平均客單價</span>
              <i class="bi bi-cart3 text-warning fs-5"></i>
            </div>
            <h3 class="fw-bold mb-1">NT$ 1,260</h3>
            <span class="badge bg-success-subtle text-success"><i class="bi bi-arrow-up"></i> +3.8%</span>
            <span class="text-muted small">穩步提升</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 2. 圖表區域 (左 8 欄走勢圖，右 4 欄佔比圖) -->
    <div class="row g-3 mb-4">
      <div class="col-12 col-xl-8">
        <div class="card border-0 shadow-sm h-100">
          <div class="card-header bg-transparent border-0 pt-3">
            <h6 class="fw-bold mb-0">營收趨勢分析 (近 7 日)</h6>
          </div>
          <div class="card-body">
            <div id="trendChart" class="chart-box"></div>
          </div>
        </div>
      </div>

      <div class="col-12 col-xl-4">
        <div class="card border-0 shadow-sm h-100">
          <div class="card-header bg-transparent border-0 pt-3">
            <h6 class="fw-bold mb-0">商品銷售品類分佈</h6>
          </div>
          <div class="card-body">
            <div id="categoryChart" class="chart-box"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- 3. 詳細明細表 -->
    <div class="card border-0 shadow-sm">
      <div class="card-header bg-transparent border-0 pt-3">
        <h6 class="fw-bold mb-0">最新成交動態</h6>
      </div>
      <div class="card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
              <tr>
                <th class="ps-4">訂單編號</th>
                <th>客戶名稱</th>
                <th>品類</th>
                <th>金額</th>
                <th>狀態</th>
                <th class="text-end pe-4">交易時間</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="ps-4 fw-semibold">#ORD-8821</td>
                <td>林志遠</td>
                <td>3C 數位家電</td>
                <td class="fw-bold text-primary">NT$ 24,900</td>
                <td><span class="badge bg-success-subtle text-success">交易成功</span></td>
                <td class="text-end pe-4 text-muted small">10 分鐘前</td>
              </tr>
              <tr>
                <td class="ps-4 fw-semibold">#ORD-8820</td>
                <td>陳美玲</td>
                <td>流行美妝</td>
                <td class="fw-bold text-primary">NT$ 3,250</td>
                <td><span class="badge bg-warning-subtle text-warning">待出貨</span></td>
                <td class="text-end pe-4 text-muted small">25 分鐘前</td>
              </tr>
              <tr>
                <td class="ps-4 fw-semibold">#ORD-8819</td>
                <td>張宏達</td>
                <td>生鮮日用品</td>
                <td class="fw-bold text-primary">NT$ 890</td>
                <td><span class="badge bg-success-subtle text-success">交易成功</span></td>
                <td class="text-end pe-4 text-muted small">1 小時前</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

  </main>

  <!-- 外部依賴載入 (Bootstrap 5 + Apache ECharts) -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/echarts@5.5.0/dist/echarts.min.js"></script>

  <!-- 圖表初始化與響應式腳本 -->
  <script>
    // 1. 初始化趨勢折線圖
    const trendChart = echarts.init(document.getElementById('trendChart'));
    trendChart.setOption({
      tooltip: { trigger: 'axis' },
      grid: { left: '3%', right: '4%', bottom: '5%', top: '5%', containLabel: true },
      xAxis: {
        type: 'category',
        boundaryGap: false,
        data: ['05-14', '05-15', '05-16', '05-17', '05-18', '05-19', '05-20']
      },
      yAxis: { type: 'value', axisLabel: { formatter: '${value}' } },
      series: [{
        name: '每日營收',
        type: 'line',
        smooth: true,
        data: [12000, 18500, 15300, 22400, 26800, 31200, 38500],
        itemStyle: { color: '#0d6efd' },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(13, 110, 253, 0.35)' },
            { offset: 1, color: 'rgba(13, 110, 253, 0.02)' }
          ])
        }
      }]
    });

    // 2. 初始化品類佔比環形圖
    const categoryChart = echarts.init(document.getElementById('categoryChart'));
    categoryChart.setOption({
      tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
      legend: { bottom: 0 },
      series: [{
        name: '品類銷售',
        type: 'pie',
        radius: ['45%', '70%'],
        center: ['50%', '45%'],
        itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
        data: [
          { value: 1450, name: '3C 數位' },
          { value: 920, name: '流行服飾' },
          { value: 680, name: '生鮮食品' },
          { value: 410, name: '生活家居' }
        ]
      }]
    });

    // 3. 響應式自適應縮放 (視窗大小變化時重繪所有圖表)
    window.addEventListener('resize', () => {
      trendChart.resize();
      categoryChart.resize();
    });
  </script>
</body>
</html>
```

---

## 資源索引

- Bootstrap 5 官方文件：https://getbootstrap.com/docs/5.3/
- Bootstrap Icons 官方圖示庫：https://icons.getbootstrap.com/
- Apache ECharts 官方範例：https://echarts.apache.org/examples/zh/index.html
- Apache ECharts 配置項手冊：https://echarts.apache.org/zh/option.html
