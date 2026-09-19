---
name: echart-statistics
version: v1.0.0
author: skill-factory
parent: echart
description: ECharts 統計圖技能，掌握熱力圖、盒須圖、平行座標、矩陣等統計型圖表，用於分佈分析、多維對比和模式識別
tags: [echarts, heatmap, boxplot, parallel, matrix, statistics]
dependency:
  parent: echart
  requires: echart-basic
---

# EChart Statistics Skill - 統計圖技能

## 任務目標

- **本 Skill 用於**：掌握統計型資料視覺化（分佈分析、多維對比、模式識別）
- **核心能力**：
  - 熱力圖：密度分析、模式識別
  - 盒須圖：分佈統計、異常檢測
  - 平行座標：多維分析、聚類識別
  - 矩陣：相關性分析、對比矩陣
- **觸發條件**：展示統計資料分佈、多維度對比時

## 圖表型別

### 熱力圖 (Heatmap)

**展示資訊**：二維資料的密度/強度分佈

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| xAxis | 類目軸/數值軸 | 橫座標 |
| yAxis | 類目軸/數值軸 | 縱座標 |
| series.data | 二維陣列 | [[x, y, value], ...] |
| visualMap | 視覺對映 | 顏色漸變 |
| label | 標籤配置 | 是否顯示數值 |

**變數關係**：x和y確定位置，value確定顏色/強度

**子型別**：
- 笛卡爾座標系熱力圖
- 散點熱力圖（基於地理/極座標）
- 日曆熱力圖
- 顏色離散對映熱力圖
- 大規模熱力圖

```javascript
option = {
  xAxis: { type: 'category', data: ['A', 'B', 'C', 'D'] },
  yAxis: { type: 'category', data: ['W', 'X', 'Y', 'Z'] },
  visualMap: { min: 0, max: 100, calculable: true, orient: 'vertical' },
  series: [{
    type: 'heatmap',
    data: [[0, 0, 5], [0, 1, 10], [1, 0, 15], [1, 1, 20]],
    label: { show: true },
    emphasis: { itemStyle: { shadowBlur: 10 } }
  }]
};
```

### 盒須圖 (Boxplot)

**展示資訊**：資料的統計分佈（中位數、四分位、異常點）

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| xAxis | 類目軸 | 橫座標（每個類目一個盒須圖） |
| yAxis | 數值軸 | 縱座標 |
| series.data | 五維陣列 | [min, Q1, median, Q3, max] |
| outlier | 異常點陣列 | 超出須的範圍的點 |

**變數關係**：展示資料的統計特徵分佈

**子型別**：
- 水平盒須圖
- 多系列盒須圖
- 帶異常點的盒須圖

```javascript
option = {
  xAxis: { type: 'category', data: ['Group1', 'Group2', 'Group3'] },
  yAxis: { type: 'value' },
  series: [{
    type: 'boxplot',
    data: [
      [[856, 940, 968, 1025, 1080], [850, 900, 950, 980, 1050]],  // Group1
      [[880, 920, 960, 1000, 1100], [860, 910, 940, 990, 1060]],  // Group2
      [[900, 940, 980, 1040, 1120], [880, 930, 970, 1020, 1090]]   // Group3
    ]
  }]
};
```

### 平行座標 (Parallel)

**展示資訊**：多維度資料的並行對比

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| parallelAxis | 平行軸陣列 | 每個維度的配置 |
| parallel | 座標系配置 | 平行座標系的佈局 |
| series.data | 多維陣列 | [dim1, dim2, dim3, ...] |

**變數關係**：同一資料點在各維度上的取值

**子型別**：
- 基礎平行座標圖
- AQI分佈平行座標
- 營養結構平行座標

```javascript
option = {
  parallelAxis: [
    { dim: 0, name: '密度' },
    { dim: 1, name: '價格' },
    { dim: 2, name: '評分' }
  ],
  parallel: { left: '5%', right: '10%', bottom: '10%', top: '20%' },
  series: [{
    type: 'parallel',
    data: [
      [0.5, 100, 4.5],
      [0.6, 200, 4.2],
      [0.7, 150, 4.8]
    ],
    lineStyle: { width: 2, opacity: 0.5 }
  }]
};
```

### 矩陣 (Matrix)

**展示資訊**：行列交叉資料、相關性矩陣

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| xAxis | 類目軸 | 列 |
| yAxis | 類目軸 | 行 |
| series.data | 二維陣列 | [[row, col, value], ...] |
| visualMap | 視覺對映 | 顏色編碼 |

**變數關係**：行與列的交叉點值

**子型別**：
- 相關矩陣（熱力圖形式）
- 混淆矩陣
- 協方差矩陣
- 股市矩陣圖
- 元素週期表

```javascript
option = {
  xAxis: { type: 'category', data: ['A', 'B', 'C', 'D'] },
  yAxis: { type: 'category', data: ['W', 'X', 'Y', 'Z'] },
  visualMap: { min: -1, max: 1, calculable: true, orient: 'vertical' },
  series: [{
    type: 'heatmap',
    data: [[0, 0, 1], [0, 1, 0.5], [1, 0, 0.5], [1, 1, 0.8]],
    label: { show: true },
    emphasis: { itemStyle: { borderColor: '#333', borderWidth: 2 } }
  }]
};
```

## 通用配置

### 視覺對映 (VisualMap)

```javascript
visualMap: {
  min: 0,                          // 最小值
  max: 100,                        // 最大值
  calculable: true,                 // 是否可拖拽
  orient: 'vertical',              // 方向
  left: 'right',                   // 位置
  inRange: {                        // 顏色範圍
    color: ['#50a3ba', '#eac736', '#d94e5d']
  },
  textStyle: { color: '#333' }
}
```

### 標籤配置

```javascript
label: {
  show: true,                      // 顯示標籤
  position: 'top',                 // 位置
  formatter: '{c}',                // 格式化
  fontSize: 12,
  color: '#333'
}
```

### 高亮狀態

```javascript
emphasis: {
  itemStyle: {
    shadowBlur: 10,
    shadowColor: 'rgba(0,0,0,0.3)'
  },
  label: { show: true }
}
```

## 資料轉換

### 原始資料轉熱力圖

```javascript
function toHeatmapData(rawData, xField, yField, valueField) {
  const data = [];
  rawData.forEach(item => {
    data.push([item[xField], item[yField], item[valueField]]);
  });
  return data;
}
```

### 統計結果轉盒須圖

```javascript
function toBoxplotData(statData) {
  return statData.map(item => {
    return [
      item.min,
      item.q1,
      item.median,
      item.q3,
      item.max
    ];
  });
}
```

## 注意事項

1. **熱力圖顏色**：選擇合適的顏色漸變突出重點區域
2. **盒須圖資料**：確保資料已正確計算五個統計量
3. **平行座標**：維度過多時考慮降維或篩選
4. **矩陣排序**：行列可按相似性排序發現模式
5. **大規模資料**：超過5000點考慮取樣或聚合

## 相關技能

- [echart-basic](../echart-basic/SKILL.md) - 基礎圖表
- [echart-multi](../echart-multi/SKILL.md) - 多圖組合
- [echart-advanced](../echart-advanced/SKILL.md) - 高階特性（dataset聚合）
