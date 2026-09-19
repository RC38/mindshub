---
name: dashboard-echarts
version: v3.0.0
author: book-skills
description: Apache ECharts 視覺化技能，掌握純前端原生 JavaScript / CDN 模式下的各種圖表配置、動態互動、主題自訂與響應式 RWD 自適應縮放
---

# Dashboard Apache ECharts (Pure JavaScript / Static HTML)

## 任務目標
- 本 Skill 用於：在純靜態 HTML 網頁中使用原生 **Apache ECharts (JS/CDN)** 快速建構專業、互動豐富的數據視覺化圖表。
- 能力包含：CDN 引入、折線圖、柱狀圖、圓餅圖/環形圖、雷達圖、儀表盤、散佈圖、Tooltip 自訂格式化、動態數據更新、Bootstrap 5 容器響應式自適應縮放 (Resize)。
- 核心優勢：**客戶端免裝 Python/pip/Streamlit**，直接以瀏覽器原生 JavaScript 渲染 Canvas/SVG，效能極高且零依賴。

---

## 快速引入與基礎步驟

### 1. 透過 CDN 引入
在 HTML 中加入官方 CDN 腳本（建議使用 5.x 穩定版本）：

```html
<!-- Apache ECharts 5.x CDN -->
<script src="https://cdn.jsdelivr.net/npm/echarts@5.5.0/dist/echarts.min.js"></script>
```

### 2. 初始化標準三部曲
1. 準備具備寬高的 DOM 容器。
2. 呼叫 `echarts.init(dom)` 建立實例。
3. 呼叫 `myChart.setOption(option)` 繪製圖表。

```html
<!-- 1. 容器必須具備寬度與高度 -->
<div id="myChart" style="width: 100%; height: 380px;"></div>

<script>
  // 2. 初始化實例
  const chartDom = document.getElementById('myChart');
  const myChart = echarts.init(chartDom);

  // 3. 配置項
  const option = {
    title: { text: '範例圖表' },
    tooltip: { trigger: 'axis' },
    xAxis: { type: 'category', data: ['一月', '二月', '三月', '四月', '五月'] },
    yAxis: { type: 'value' },
    series: [{
      data: [150, 230, 224, 218, 135],
      type: 'line'
    }]
  };

  myChart.setOption(option);

  // 4. 響應式監聽：視窗改變大小時自動重繪
  window.addEventListener('resize', () => myChart.resize());
</script>
```

---

## 看板核心圖表配置實例

### 1. 平滑折線與漸層面積圖 (Smooth Line & Gradient Area)
適合展示趨勢分析（如營收走勢、流量波動）：

```javascript
const lineOption = {
  tooltip: {
    trigger: 'axis',
    axisPointer: { type: 'cross', label: { backgroundColor: '#6a7985' } }
  },
  legend: { data: ['本月營收', '上月同期'], bottom: 0 },
  grid: { left: '3%', right: '4%', bottom: '10%', top: '10%', containLabel: true },
  xAxis: {
    type: 'category',
    boundaryGap: false,
    data: ['01日', '05日', '10日', '15日', '20日', '25日', '30日']
  },
  yAxis: { type: 'value', axisLabel: { formatter: 'NT$ {value}' } },
  series: [
    {
      name: '本月營收',
      type: 'line',
      smooth: true,
      data: [3200, 4500, 4100, 5800, 6200, 7800, 8900],
      itemStyle: { color: '#0d6efd' },
      areaStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(13, 110, 253, 0.4)' },
          { offset: 1, color: 'rgba(13, 110, 253, 0.02)' }
        ])
      }
    },
    {
      name: '上月同期',
      type: 'line',
      smooth: true,
      lineStyle: { type: 'dashed' },
      data: [2800, 3900, 4300, 4900, 5300, 6100, 7200],
      itemStyle: { color: '#6c757d' }
    }
  ]
};
```

---

### 2. 圓角柱狀圖與雙系列堆疊 (Bar Chart & Stacked Bars)
適合展示多品類業績對比或達成度：

```javascript
const barOption = {
  tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
  legend: { data: ['線上門市', '實體專櫃'], bottom: 0 },
  grid: { left: '3%', right: '4%', bottom: '10%', top: '8%', containLabel: true },
  xAxis: {
    type: 'category',
    data: ['電子3C', '服裝美妝', '生鮮日用', '運動休閒', '圖書文具']
  },
  yAxis: { type: 'value' },
  series: [
    {
      name: '線上門市',
      type: 'bar',
      stack: 'total',
      barMaxWidth: 35,
      itemStyle: { borderRadius: [0, 0, 0, 0], color: '#0d6efd' },
      data: [320, 450, 280, 210, 150]
    },
    {
      name: '實體專櫃',
      type: 'bar',
      stack: 'total',
      barMaxWidth: 35,
      itemStyle: { borderRadius: [6, 6, 0, 0], color: '#20c997' },
      data: [180, 220, 190, 140, 90]
    }
  ]
};
```

---

### 3. 環形圓餅圖與南丁格爾玫瑰圖 (Donut & Rose Chart)
適合展示市場份額、渠道來源或佔比分析：

```javascript
const pieOption = {
  tooltip: {
    trigger: 'item',
    formatter: '{b}<br/>數值：<b>{c}</b> ({d}%)'
  },
  legend: { orient: 'horizontal', bottom: 0 },
  series: [
    {
      name: '營收渠道',
      type: 'pie',
      radius: ['45%', '70%'], // 內半徑與外半徑，形成環形
      center: ['50%', '45%'],
      avoidLabelOverlap: false,
      itemStyle: {
        borderRadius: 8,
        borderColor: '#fff',
        borderWidth: 2
      },
      label: {
        show: false,
        position: 'center'
      },
      emphasis: {
        label: {
          show: true,
          fontSize: 16,
          fontWeight: 'bold',
          formatter: '{b}\n{d}%'
        }
      },
      data: [
        { value: 1048, name: '官網商城' },
        { value: 735, name: 'APP 下單' },
        { value: 580, name: '社群導購' },
        { value: 484, name: '加盟實體' },
        { value: 300, name: '電話訂購' }
      ]
    }
  ]
};
```

---

### 4. 關鍵 KPI 達成率儀表盤 (Gauge Chart)
適合展示單一指標達成進度（如目標完成率、伺服器 CPU 使用率）：

```javascript
const gaugeOption = {
  tooltip: { formatter: '{a} <br/>{b} : {c}%' },
  series: [
    {
      name: '年度業績',
      type: 'gauge',
      radius: '85%',
      progress: {
        show: true,
        width: 14,
        itemStyle: { color: '#0d6efd' }
      },
      axisLine: { lineStyle: { width: 14 } },
      axisTick: { show: false },
      splitLine: { length: 6, lineStyle: { width: 1, color: '#999' } },
      axisLabel: { distance: 18, color: '#999', fontSize: 11 },
      anchor: { show: true, showAbove: true, size: 14, itemStyle: { borderWidth: 4 } },
      title: { show: true, offsetCenter: [0, '70%'], fontSize: 14, color: '#666' },
      detail: {
        valueAnimation: true,
        fontSize: 26,
        offsetCenter: [0, '40%'],
        formatter: '{value}%',
        color: '#212529',
        fontWeight: 'bold'
      },
      data: [{ value: 78.5, name: '年度營收目標達成率' }]
    }
  ]
};
```

---

### 5. 多維能力雷達圖 (Radar Chart)
適合多維度評估（如員工績效評比、各部門指標分析）：

```javascript
const radarOption = {
  tooltip: {},
  radar: {
    indicator: [
      { name: '銷售轉化', max: 100 },
      { name: '客戶滿意度', max: 100 },
      { name: '訂單交付', max: 100 },
      { name: '成本控制', max: 100 },
      { name: '售後響應', max: 100 }
    ],
    radius: '65%'
  },
  series: [
    {
      name: '團隊綜合指標',
      type: 'radar',
      data: [
        {
          value: [88, 92, 75, 82, 95],
          name: '本期指標',
          areaStyle: { color: 'rgba(13, 110, 253, 0.3)' },
          itemStyle: { color: '#0d6efd' }
        },
        {
          value: [70, 80, 85, 70, 78],
          name: '同期基準',
          areaStyle: { color: 'rgba(108, 117, 125, 0.2)' },
          itemStyle: { color: '#6c757d' }
        }
      ]
    }
  ]
};
```

---

## 與 Bootstrap 5 整合的關鍵技巧

### 1. 響應式 Resize 管理 (避免圖表破版)
當視窗大小改變或手機橫豎屏切換時，必須主動通知所有 ECharts 實例調整尺寸：

```javascript
// 統一註冊圖表實例管理陣列
const chartInstances = [];

// 建立圖表時加入陣列
chartInstances.push(revenueChart);
chartInstances.push(categoryPieChart);

// 監聽視窗尺寸改變
window.addEventListener('resize', () => {
  chartInstances.forEach(chart => {
    if (chart) chart.resize();
  });
});
```

### 2. 解決 Bootstrap 5 Tab / Collapse 隱藏導致圖表寬度變 0 的問題
**重要常規問題**：當 ECharts 放置於預設隱藏的 Tab 頁籤 (`tab-pane`) 或摺疊區塊時，由於初始化時容器寬度為 0，切換過去會發現圖表縮成一條線。
**解決方案**：監聽 Bootstrap 的 `shown.bs.tab` 事件觸發 `chart.resize()`：

```javascript
// 監聽所有 Tab 切換完成事件
const tabElements = document.querySelectorAll('button[data-bs-toggle="tab"]');
tabElements.forEach(tabEl => {
  tabEl.addEventListener('shown.bs.tab', (event) => {
    // 取得當前顯示的 Tab 容器中的 ECharts
    const targetPane = document.querySelector(event.target.getAttribute('data-bs-target'));
    if (targetPane) {
      const chartsInPane = targetPane.querySelectorAll('div[id]');
      chartsInPane.forEach(chartDiv => {
        const instance = echarts.getInstanceByDom(chartDiv);
        if (instance) {
          instance.resize();
        }
      });
    }
  });
});
```

### 3. 動態數據篩選切換
在靜態前端中，點選下拉選單或按鈕後，透過 `chart.setOption()` 即時刷新數據：

```javascript
function onCategoryFilterChange(selectedCategory) {
  // 假定獲取到的最新數據
  const updatedData = fetchFilteredData(selectedCategory);

  // setOption 具備增量合併特性，僅需傳入要更新的欄位
  myChart.setOption({
    series: [{
      data: updatedData.series
    }]
  });
}
```

---

## 與進階 EChart 技能族協同 (Integration with `tool/echart`)

當儀表板需要超越常規折線、柱狀、圓餅等基礎圖表，涉及**複雜業務圖表、地理空間、金融量化、3D 視覺化或多圖深度連動**時，**強烈推薦關聯並調用專門的 ECharts 全技能庫**：[`tool/echart`](file:///Volumes/tf-1tb/googledriver/96.code/github/skills/agent-skills/tool/echart/SKILL.md)。

### 職責劃分與分工

| 技能模組 | 定位與主要職責 |
| :--- | :--- |
| **`dashboard-echarts` (本技能)** | **看板工程與容器整合大腦**：專注於與 Bootstrap 5 RWD 佈局容器無縫對接、視窗縮放 Resize 管理、Bootstrap Tab / Collapse 隱藏容器防破版、KPI 圖表快配、前端篩選聯動。 |
| **[`tool/echart`](file:///Volumes/tf-1tb/googledriver/96.code/github/skills/agent-skills/tool/echart/SKILL.md) (進階技能族)** | **專業級圖表百科全書**：提供 Apache ECharts 完整 8 大專業子技能、365+ 官方精選範例與進階 `option` 深度配置。 |

### 進階圖表查找索引

當看板有特定進階視覺化需求時，可直接索引至 `tool/echart` 對應子技能：

| 看板進階展示需求 | 推薦調用之 `tool/echart` 子技能 | 快速參考路徑 |
| :--- | :--- | :--- |
| **漏斗轉化流向、組織層級、關係網絡** | `echart-relation`（桑基圖、樹圖、旭日圖、關係圖） | [`tool/echart/skills/echart-relation/`](file:///Volumes/tf-1tb/googledriver/96.code/github/skills/agent-skills/tool/echart/skills/echart-relation/) |
| **區域熱力、矩陣相關性、離散統計** | `echart-statistics`（熱力圖、盒須圖、平行座標） | [`tool/echart/skills/echart-statistics/`](file:///Volumes/tf-1tb/googledriver/96.code/github/skills/agent-skills/tool/echart/skills/echart-statistics/) |
| **股票 K 線、布林通道、多維雷達圖** | `echart-finance`（K線圖、雷達圖、儀表盤） | [`tool/echart/skills/echart-finance/`](file:///Volumes/tf-1tb/googledriver/96.code/github/skills/agent-skills/tool/echart/skills/echart-finance/) |
| **全台/全球門市地圖、GPS 軌跡、3D 地球** | `echart-geo`（GeoJSON 地圖、3D 地球、飛線圖） | [`tool/echart/skills/echart-geo/`](file:///Volumes/tf-1tb/googledriver/96.code/github/skills/agent-skills/tool/echart/skills/echart-geo/) |
| **3D 曲面、3D 柱狀空間分佈** | `echart-3d`（ECharts-GL、3D 柱狀/散佈圖） | [`tool/echart/skills/echart-3d/`](file:///Volumes/tf-1tb/googledriver/96.code/github/skills/agent-skills/tool/echart/skills/echart-3d/) |
| **大量數據高效渲染、時間軸滑塊、多維度 dataset** | `echart-advanced`（dataset 數據集抽象、dataZoom） | [`tool/echart/skills/echart-advanced/`](file:///Volumes/tf-1tb/googledriver/96.code/github/skills/agent-skills/tool/echart/skills/echart-advanced/) |
| **多圖跨畫布游標聯動、Timeline 時間輪播** | `echart-multi`（Grid 多網格組合、圖表聯動） | [`tool/echart/skills/echart-multi/`](file:///Volumes/tf-1tb/googledriver/96.code/github/skills/agent-skills/tool/echart/skills/echart-multi/) |

> [!TIP]
> 更多官方 39 大類共 365 個範例的直達網址索引，請直接查閱：[`tool/echart/references/範例清單.md`](file:///Volumes/tf-1tb/googledriver/96.code/github/skills/agent-skills/tool/echart/references/範例清單.md)。

---

## 最佳實踐建議

1. **圖表高度必須預設**：ECharts 不會自動依內容撐開高度，容器必須明確寫入 CSS 高度（如 `height: 350px`）。
2. **顏色搭配一致性**：建議沿用 Bootstrap 主題色彩（Primary `#0d6efd`, Success `#198754`, Info `#0dcaf0`, Warning `#ffc107`, Danger `#dc3545`），維持全站設計語彙統一。
3. **Tooltip 美化**：利用 `tooltip.formatter` 回傳 HTML 標籤，可直接使用 Bootstrap 工具類（如 `fw-bold`, `text-primary`）自訂懸停卡片。
4. **離線環境支援**：若需要在無網路內網環境運行，只需將 `echarts.min.js` 下載至專案目錄本機引入即可。
