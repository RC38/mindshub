---
name: echart-basic
version: v1.0.0
author: skill-factory
parent: echart
description: ECharts 基礎圖表技能，掌握折線圖、柱狀圖、餅圖、散點圖的配置和用法，包含資料系列、座標軸、樣式定製等
tags: [echarts, line, bar, pie, scatter, basic, chart]
dependency:
  parent: echart
  requires: null
---

# EChart Basic Skill - 基礎圖表技能

## 任務目標

- **本 Skill 用於**：掌握 ECharts 基礎圖表（折線圖、柱狀圖、餅圖、散點圖）的配置和使用
- **核心能力**：
  - 折線圖：趨勢變化、對比分析
  - 柱狀圖：分類對比、數量統計
  - 餅圖：佔比分析、分佈統計
  - 散點圖：相關性分析、多維度分佈
- **觸發條件**：需要展示基礎資料視覺化時

## 圖表型別

### 折線圖 (Line Chart)

**展示資訊**：資料隨時間/類目的變化趨勢

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| xAxis | 類目軸/數值軸 | 橫座標 |
| yAxis | 數值軸 | 縱座標 |
| series.data | 陣列 | 每個點的數值 |

**變數關係**：x軸與y軸一一對應，支援多系列對比

**子型別**：
- 基礎折線圖
- 平滑折線圖 (smooth)
- 面積圖 (areaStyle)
- 堆疊折線圖 (stack)
- 漸變面積圖
- 階梯折線圖 (step)
- 多X軸折線圖

```javascript
option = {
  xAxis: { type: 'category', data: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] },
  yAxis: { type: 'value' },
  series: [{
    type: 'line',
    data: [820, 932, 901, 934, 1290, 1330, 1320],
    smooth: true,
    areaStyle: { gradient: [...] }
  }]
};
```

### 柱狀圖 (Bar Chart)

**展示資訊**：不同類目的數值對比

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| xAxis | 類目軸 | 橫座標 |
| yAxis | 數值軸 | 縱座標 |
| series.data | 陣列 | 每個柱子的數值 |

**變數關係**：x軸類目與y軸數值一一對應

**子型別**：
- 基礎柱狀圖
- 堆疊柱狀圖 (stack)
- 環形柱狀圖 (barWidth + radius)
- 瀑布圖
- 南北對比柱狀圖
- 極座標柱狀圖

```javascript
option = {
  xAxis: { type: 'category', data: ['Apple', 'Banana', 'Orange'] },
  yAxis: { type: 'value' },
  series: [{
    type: 'bar',
    data: [120, 200, 150],
    itemStyle: { color: '#5470C6' }
  }]
};
```

### 餅圖 (Pie Chart)

**展示資訊**：部分與整體的比例關係

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| series.data | 物件陣列 | [{name: 'A', value: 100}] |
| radius | 數值/陣列 | 半徑 |
| center | 陣列 | 圓心位置 |

**變數關係**：各資料項之和為整體

**子型別**：
- 基礎餅圖
- 環形圖 (radius: ['40%', '70%'])
- 南丁格爾玫瑰圖 (roseType: 'area')
- 半環形圖
- 巢狀餅圖
- 富文字標籤餅圖

```javascript
option = {
  series: [{
    type: 'pie',
    radius: ['40%', '70%'],
    data: [
      { name: 'Apple', value: 100 },
      { name: 'Banana', value: 200 },
      { name: 'Orange', value: 150 }
    ],
    roseType: 'area'
  }]
};
```

### 散點圖 (Scatter Chart)

**展示資訊**：兩個數值變數的相關性，多維度分佈

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| xAxis | 數值軸 | 橫座標 |
| yAxis | 數值軸 | 縱座標 |
| series.data | 二維陣列/物件 | [x, y] 或 [x, y, size] |
| symbolSize | 數值/函式 | 點的大小 |
| visualMap | 視覺對映 | 顏色編碼第三維度 |

**變數關係**：x與y的相關性，size編碼額外維度

**子型別**：
- 基礎散點圖
- 氣泡圖 (size編碼第三維)
- 漣漪特效散點圖 (effectScatter)
- 大規模散點圖
- 迴歸散點圖 (線性/多項式/對數)

```javascript
option = {
  xAxis: { type: 'value' },
  yAxis: { type: 'value' },
  series: [{
    type: 'scatter',
    symbolSize: function(data) { return data[2]; },
    data: [[10, 5, 20], [20, 15, 40], [30, 25, 60]],
    visualMap: { min: 0, max: 100, dimension: 2 }
  }]
};
```

## 通用配置

### 座標軸配置

```javascript
xAxis: {
  type: 'category',  // 類目軸
  data: ['類目1', '類目2', '類目3']
},
yAxis: {
  type: 'value',     // 數值軸
  min: 0,            // 最小值
  max: 100,          // 最大值
  splitNumber: 5     // 分割段數
}
```

### 系列通用配置

```javascript
series: [{
  type: 'line',      // 圖表型別
  name: '系列名稱',   // 系列名
  data: [...],       // 資料
  itemStyle: {        // 樣式
    color: '#5470C6'
  },
  emphasis: {        // 高亮狀態
    itemStyle: { shadowBlur: 10 }
  }
}]
```

### 提示框(Tooltip)

```javascript
tooltip: {
  trigger: 'item',   // 'item' | 'axis' | 'none'
  formatter: function(params) {
    return params.name + ': ' + params.value;
  }
}
```

## 資料格式

### 陣列格式

```javascript
data: [120, 200, 150]  // 簡單數值陣列
```

### 物件陣列格式

```javascript
data: [
  { name: 'Mon', value: 120 },
  { name: 'Tue', value: 200 }
]
```

### 多維陣列格式

```javascript
data: [
  [10, 20, 30],  // [x, y, size]
  [15, 25, 40]
]
```

## 樣式定製

### 顏色

```javascript
color: ['#5470C6', '#91CC75', '#FAC858', '#EE6666']
```

### 文字樣式

```javascript
textStyle: {
  fontFamily: 'Arial',
  fontSize: 12,
  color: '#333'
}
```

### 圖形樣式

```javascript
itemStyle: {
  color: '#5470C6',
  borderColor: '#fff',
  borderWidth: 2,
  shadowBlur: 10,
  shadowColor: 'rgba(0,0,0,0.3)'
}
```

## 注意事項

1. **資料量**：超過1000個資料點考慮使用 dataZoom 或取樣
2. **座標軸型別**：時間資料用 'time' 型別，類目用 'category'
3. **餅圖示籤**：避免標籤過多導致重疊，使用引導線或富文字
4. **散點大小**：symbolSize 函式要控制好返回值範圍
5. **動畫**：大資料量時考慮關閉動畫 (animation: false)

## 相關技能

- [echart-finance](../echart-finance/SKILL.md) - 金融圖表（K線圖、雷達圖）
- [echart-multi](../echart-multi/SKILL.md) - 多圖組合（grid疊加）
- [echart-advanced](../echart-advanced/SKILL.md) - 高階特性（dataset資料處理）
