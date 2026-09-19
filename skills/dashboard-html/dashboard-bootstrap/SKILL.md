---
name: dashboard-bootstrap
version: v1.0.0
author: book-skills
description: Bootstrap 5 響應式網頁設計 (RWD) 與看板元件技能，掌握網格佈局、KPI 指標卡片、導覽列、側邊欄、表格與表單控制項，建構現代化無依賴的前端數據看板
---

# Dashboard Bootstrap 5 (RWD & UI Components)

## 任務目標
- 本 Skill 用於：使用 Bootstrap 5 快速建構美觀、自適應多端螢幕（手機、平板、桌面）的數據看板介面。
- 能力包含：RWD 網格系統、KPI 指標摘要卡片、導覽列與側邊欄、圖表卡片容器、響應式數據表、看板篩選控制項、深色模式切換。
- 核心優勢：**客戶端純靜態執行，免裝 pip、Python 或 Streamlit**，直接透過 CDN 引入，瀏覽器秒開。

---

## 核心引入方式

### 1. CDN 引入 (標準推薦)
在 HTML `<head>` 與 `<body>` 結尾處引入 Bootstrap 5.3+ 與 Bootstrap Icons：

```html
<!DOCTYPE html>
<html lang="zh-Hant" data-bs-theme="light">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>數據看板</title>
  <!-- Bootstrap 5.3 CSS -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <!-- Bootstrap Icons -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
</head>
<body class="bg-body-tertiary">
  <!-- 頁面內容 -->

  <!-- Bootstrap 5 JS Bundle (包含 Popper) -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
```

---

## 常用元件與排版範例

### 1. RWD 響應式網格 (Grid System)
看板版面推薦採用 `container-fluid` 全寬佈局與 `row g-3`（欄位間距）：

```html
<!-- 4 欄適配：手機單欄 (col-12)、平板雙欄 (col-md-6)、大螢幕四欄 (col-xl-3) -->
<div class="container-fluid py-4">
  <div class="row g-3">
    <div class="col-12 col-md-6 col-xl-3">
      <!-- 區塊 1 -->
    </div>
    <div class="col-12 col-md-6 col-xl-3">
      <!-- 區塊 2 -->
    </div>
    <div class="col-12 col-md-6 col-xl-3">
      <!-- 區塊 3 -->
    </div>
    <div class="col-12 col-md-6 col-xl-3">
      <!-- 區塊 4 -->
    </div>
  </div>
</div>
```

---

### 2. 核心 KPI 指標卡片 (Metric Cards)
數據看板頂部最核心的數值統計卡片，包含彩色左側邊框、增減百分比徽章與視覺圖示：

```html
<div class="row g-3 mb-4">
  <!-- 總銷售額 -->
  <div class="col-12 col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm border-start border-primary border-4 h-100">
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <span class="text-muted small fw-semibold text-uppercase">總銷售額</span>
          <div class="bg-primary-subtle text-primary rounded-circle p-2 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
            <i class="bi bi-currency-dollar fs-5"></i>
          </div>
        </div>
        <h3 class="fw-bold mb-1">NT$ 2,458,900</h3>
        <div class="small">
          <span class="badge bg-success-subtle text-success me-1">
            <i class="bi bi-arrow-up-short"></i> +12.5%
          </span>
          <span class="text-muted">較上月同期</span>
        </div>
      </div>
    </div>
  </div>

  <!-- 新增訂單 -->
  <div class="col-12 col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm border-start border-success border-4 h-100">
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <span class="text-muted small fw-semibold text-uppercase">今日訂單</span>
          <div class="bg-success-subtle text-success rounded-circle p-2 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
            <i class="bi bi-cart-check fs-5"></i>
          </div>
        </div>
        <h3 class="fw-bold mb-1">1,280 筆</h3>
        <div class="small">
          <span class="badge bg-success-subtle text-success me-1">
            <i class="bi bi-arrow-up-short"></i> +8.2%
          </span>
          <span class="text-muted">達標率 92%</span>
        </div>
      </div>
    </div>
  </div>

  <!-- 活躍用戶 -->
  <div class="col-12 col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm border-start border-info border-4 h-100">
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <span class="text-muted small fw-semibold text-uppercase">活躍用戶</span>
          <div class="bg-info-subtle text-info rounded-circle p-2 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
            <i class="bi bi-people fs-5"></i>
          </div>
        </div>
        <h3 class="fw-bold mb-1">45,600 人</h3>
        <div class="small">
          <span class="badge bg-danger-subtle text-danger me-1">
            <i class="bi bi-arrow-down-short"></i> -1.4%
          </span>
          <span class="text-muted">日均活躍</span>
        </div>
      </div>
    </div>
  </div>

  <!-- 異常提醒 -->
  <div class="col-12 col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm border-start border-warning border-4 h-100">
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <span class="text-muted small fw-semibold text-uppercase">待處理警報</span>
          <div class="bg-warning-subtle text-warning rounded-circle p-2 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
            <i class="bi bi-exclamation-triangle fs-5"></i>
          </div>
        </div>
        <h3 class="fw-bold mb-1">3 件</h3>
        <div class="small">
          <span class="badge bg-warning-subtle text-warning me-1">待審核</span>
          <span class="text-muted">2 小時內更新</span>
        </div>
      </div>
    </div>
  </div>
</div>
```

---

### 3. 圖表容器卡片 (Chart Card Container)
用於包裹 Apache ECharts 的標準容器，具備標題列、篩選按鈕組、與固定高度的畫布容器：

```html
<div class="card border-0 shadow-sm mb-4">
  <div class="card-header bg-transparent border-0 d-flex justify-content-between align-items-center pt-3 pb-0">
    <div>
      <h6 class="fw-bold mb-0">趨勢分析報表</h6>
      <small class="text-muted">每日營收與訂單轉換統計</small>
    </div>
    <!-- 快捷切換按鈕組 -->
    <div class="btn-group btn-group-sm" role="group">
      <button type="button" class="btn btn-outline-secondary active" onclick="updateTimeRange('7d')">近7天</button>
      <button type="button" class="btn btn-outline-secondary" onclick="updateTimeRange('30d')">近30天</button>
      <button type="button" class="btn btn-outline-secondary" onclick="updateTimeRange('1y')">今年</button>
    </div>
  </div>
  <div class="card-body">
    <!-- ECharts 渲染容器 (必須指定 height，寬度 100% 自適應) -->
    <div id="revenueChart" style="width: 100%; height: 360px;"></div>
  </div>
</div>
```

---

### 4. 側邊欄與導覽列 (Navbar & Offcanvas Sidebar)
支援桌機寬螢幕固定側邊欄，以及手機平板自適應 Offcanvas 抽屜選單：

```html
<!-- 頂部導覽列 -->
<nav class="navbar navbar-expand-lg bg-white border-bottom sticky-top">
  <div class="container-fluid">
    <!-- 手機端側邊欄漢堡按鈕 -->
    <button class="btn btn-light d-lg-none me-2" type="button" data-bs-toggle="offcanvas" data-bs-target="#sidebarOffcanvas">
      <i class="bi bi-list fs-5"></i>
    </button>
    <a class="navbar-brand fw-bold d-flex align-items-center gap-2" href="#">
      <i class="bi bi-speedometer2 text-primary fs-4"></i>
      <span>BI 數據中心</span>
    </a>
    
    <!-- 右側功能區 -->
    <div class="ms-auto d-flex align-items-center gap-3">
      <!-- 主題切換按鈕 -->
      <button class="btn btn-outline-secondary btn-sm" id="btnThemeToggle" title="切換深淺模式">
        <i class="bi bi-moon-stars" id="themeIcon"></i>
      </button>
      <div class="dropdown">
        <button class="btn btn-sm btn-light dropdown-toggle d-flex align-items-center gap-2" data-bs-toggle="dropdown">
          <i class="bi bi-person-circle"></i> 管理員
        </button>
        <ul class="dropdown-menu dropdown-menu-end shadow-sm">
          <li><a class="dropdown-item" href="#"><i class="bi bi-gear me-2"></i>設定</a></li>
          <li><hr class="dropdown-divider"></li>
          <li><a class="dropdown-item text-danger" href="#"><i class="bi bi-box-arrow-right me-2"></i>登出</a></li>
        </ul>
      </div>
    </div>
  </div>
</nav>

<!-- 手機端 Offcanvas 側邊選單 -->
<div class="offcanvas offcanvas-start" tabindex="-1" id="sidebarOffcanvas">
  <div class="offcanvas-header border-bottom">
    <h5 class="offcanvas-title fw-bold"><i class="bi bi-speedometer2 text-primary me-2"></i>導覽選單</h5>
    <button type="button" class="btn-close" data-bs-dismiss="offcanvas"></button>
  </div>
  <div class="offcanvas-body p-0">
    <div class="list-group list-group-flush">
      <a href="#" class="list-group-item list-group-item-action active"><i class="bi bi-house-door me-2"></i>總覽總結</a>
      <a href="#" class="list-group-item list-group-item-action"><i class="bi bi-graph-up me-2"></i>銷售分析</a>
      <a href="#" class="list-group-item list-group-item-action"><i class="bi bi-people me-2"></i>客戶分佈</a>
      <a href="#" class="list-group-item list-group-item-action"><i class="bi bi-file-earmark-spreadsheet me-2"></i>報表明細</a>
    </div>
  </div>
</div>
```

---

### 5. 數據看板篩選控制列 (Filter Bar)
在圖表上方提供多維度篩選元件（類別、日期區間、關鍵字搜尋）：

```html
<div class="card border-0 shadow-sm mb-4">
  <div class="card-body">
    <form class="row g-3 align-items-end" id="filterForm">
      <div class="col-12 col-sm-6 col-md-3">
        <label class="form-label small fw-semibold text-muted">業務類別</label>
        <select class="form-select form-select-sm" id="categoryFilter">
          <option value="all" selected>全部分類</option>
          <option value="electronics">3C 數位家電</option>
          <option value="clothing">流行服飾</option>
          <option value="food">生鮮食品</option>
        </select>
      </div>
      <div class="col-12 col-sm-6 col-md-3">
        <label class="form-label small fw-semibold text-muted">地區門市</label>
        <select class="form-select form-select-sm" id="regionFilter">
          <option value="all" selected>全部地區</option>
          <option value="north">北部營運處</option>
          <option value="central">中部營運處</option>
          <option value="south">南部營運處</option>
        </select>
      </div>
      <div class="col-12 col-sm-6 col-md-3">
        <label class="form-label small fw-semibold text-muted">查詢關鍵字</label>
        <input type="text" class="form-control form-control-sm" placeholder="輸入商品或客戶名稱" id="keywordFilter">
      </div>
      <div class="col-12 col-sm-6 col-md-3 d-flex gap-2">
        <button type="button" class="btn btn-primary btn-sm flex-fill" onclick="applyFilters()">
          <i class="bi bi-funnel me-1"></i>套用篩選
        </button>
        <button type="button" class="btn btn-outline-secondary btn-sm" onclick="resetFilters()">
          <i class="bi bi-arrow-counterclockwise"></i>重設
        </button>
      </div>
    </form>
  </div>
</div>
```

---

### 6. 響應式數據表格 (Responsive Table)
搭配 `table-responsive` 容器，在手機小螢幕上支援水平滑動，維持版面正常：

```html
<div class="card border-0 shadow-sm mb-4">
  <div class="card-header bg-transparent border-0 d-flex justify-content-between align-items-center pt-3">
    <h6 class="fw-bold mb-0">最新交易清單</h6>
    <button class="btn btn-outline-primary btn-sm" onclick="exportCSV()">
      <i class="bi bi-download me-1"></i>導出 CSV
    </button>
  </div>
  <div class="card-body p-0">
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th class="ps-3">訂單編號</th>
            <th>客戶名稱</th>
            <th>品類</th>
            <th>金額</th>
            <th>狀態</th>
            <th class="text-end pe-3">下單時間</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td class="ps-3 fw-semibold">#ORD-9021</td>
            <td>王小明</td>
            <td>3C 數位</td>
            <td class="fw-bold text-primary">NT$ 18,900</td>
            <td><span class="badge bg-success-subtle text-success">已完成</span></td>
            <td class="text-end pe-3 text-muted small">2024-05-20 14:32</td>
          </tr>
          <tr>
            <td class="ps-3 fw-semibold">#ORD-9022</td>
            <td>李美華</td>
            <td>流行服飾</td>
            <td class="fw-bold text-primary">NT$ 3,450</td>
            <td><span class="badge bg-warning-subtle text-warning">出貨中</span></td>
            <td class="text-end pe-3 text-muted small">2024-05-20 15:10</td>
          </tr>
          <tr>
            <td class="ps-3 fw-semibold">#ORD-9023</td>
            <td>張志豪</td>
            <td>生鮮食品</td>
            <td class="fw-bold text-primary">NT$ 980</td>
            <td><span class="badge bg-secondary-subtle text-secondary">處理中</span></td>
            <td class="text-end pe-3 text-muted small">2024-05-20 16:05</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</div>
```

---

### 7. 一鍵深色模式切換 (Dark Mode Toggle)
Bootstrap 5.3 原生支援 `data-bs-theme` 屬性，搭配微量 JavaScript 即可實現深色/淺色主題切換：

```javascript
// 主題切換邏輯
const btnThemeToggle = document.getElementById('btnThemeToggle');
const themeIcon = document.getElementById('themeIcon');

btnThemeToggle.addEventListener('click', () => {
  const currentTheme = document.documentElement.getAttribute('data-bs-theme');
  const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
  document.documentElement.setAttribute('data-bs-theme', newTheme);
  
  // 切換圖示
  if (newTheme === 'dark') {
    themeIcon.classList.replace('bi-moon-stars', 'bi-sun');
  } else {
    themeIcon.classList.replace('bi-sun', 'bi-moon-stars');
  }
  
  // 通知已掛載的 ECharts 圖表重刷主題 (若有需要)
  if (typeof onThemeChanged === 'function') {
    onThemeChanged(newTheme);
  }
});
```

---

## 最佳實踐重點

1. **圖表容器必須具備明確尺寸**：ECharts 在初始化時必須能取得容器的像素尺寸。建議在卡片 body 的 div 加上 `style="width: 100%; height: 360px;"`。
2. **手機端導覽適配**：大螢幕可使用側邊欄或頂部選單；小於 992px (`lg`) 建議改用 `offcanvas` 抽屜選單，保留更多可視空間給看板圖表。
3. **色彩語意統一**：
   - 成功/增長：`text-success` / `bg-success-subtle`
   - 警示/風險：`text-warning` / `bg-warning-subtle`
   - 衰退/錯誤：`text-danger` / `bg-danger-subtle`
   - 主要指標：`text-primary` / `bg-primary-subtle`
4. **無依賴分發**：整頁為純 HTML + CSS + JS，可直接存檔發送給客戶或部署至 GitHub Pages、S3、Nginx 等任何靜態空間。
