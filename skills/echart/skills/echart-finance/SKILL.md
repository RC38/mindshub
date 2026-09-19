---
name: echart-finance
version: v1.0.0
author: skill-factory
parent: echart
description: ECharts 金融圖技能，掌握K線圖、雷達圖、儀表盤等金融場景圖表，用於股票走勢、能力評估和指標監控
tags: [echarts, candlestick, radar, gauge, finance, kline]
dependency:
  parent: echart
  requires: echart-basic
---

# EChart Finance Skill - 金融圖技能

## 任務目標

- **本 Skill 用於**：掌握金融場景資料視覺化（股票走勢、能力評估、指標監控）
- **核心能力**：
  - K線圖：股票期貨走勢、波動分析
  - 雷達圖：能力評估、多維對比
  - 儀表盤：進度監控、指標展示
- **觸發條件**：展示金融資料、評估指標、進度監控時

## 圖表型別

### K線圖 (Candlestick)

**展示資訊**：股票/期貨的OHLC（開盤、最高、收盤、最低價）

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| xAxis | 類目軸/時間軸 | 橫座標（時間） |
| yAxis | 數值軸 | 縱座標（價格） |
| series.data | 陣列 | [open, close, lowest, highest] |
| series.itemStyle | 樣式 | K線顏色配置 |

**變數關係**：時間序列的四個價格點

**子型別**：
- 基礎K線圖
- 上證指數K線圖
- OHLC圖（自定義系列）
- 大資料量K線圖
- 觸屏互動K線圖
- 斷軸K線圖

```javascript
option = {
  xAxis: { type: 'category', data: ['2024-01', '2024-02', '2024-03'] },
  yAxis: { type: 'value' },
  series: [{
    type: 'candlestick',
    data: [
      [20, 30, 15, 35],   // [open, close, low, high]
      [25, 35, 20, 40],
      [30, 25, 18, 38]
    ],
    itemStyle: {
      color: '#eb5454',       // 上漲顏色
      color0: '#47b262',      // 下跌顏色
      borderColor: '#eb5454',
      borderColor0: '#47b262'
    }
  }]
};
```

### 雷達圖 (Radar)

**展示資訊**：多維度能力/屬性對比

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| radar | 雷達座標系 | 維度配置 |
| indicator | 指標陣列 | [{name, max, min}] |
| series.data | 陣列 | 各維度取值 |

**變數關係**：各維度數值的相對位置和麵積

**子型別**：
- 基礎雷達圖
- 多雷達圖（疊加）
- AQI雷達圖
- 自定義樣式雷達圖
- 瀏覽器佔比變化雷達圖

```javascript
option = {
  radar: {
    indicator: [
      { name: '速度', max: 100 },
      { name: '價格', max: 100 },
      { name: '功能', max: 100 },
      { name: '外觀', max: 100 },
      { name: '油耗', max: 100 }
    ],
    shape: 'polygon',        // 'polygon' | 'circle'
    splitNumber: 5
  },
  series: [{
    type: 'radar',
    data: [{
      value: [85, 60, 90, 75, 50],
      name: '車型A',
      areaStyle: { opacity: 0.3 }
    }, {
      value: [70, 80, 70, 85, 70],
      name: '車型B',
      areaStyle: { opacity: 0.3 }
    }]
  }]
};
```

### 儀表盤 (Gauge)

**展示資訊**：單一指標與目標/範圍的對比

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| series.data | 數值 | 當前值 |
| min | 最小值 | 刻度起始值 |
| max | 最大值 | 刻度結束值 |
| radius | 半徑 | 儀表盤大小 |
| startAngle | 起始角度 | 指標起始 |
| endAngle | 結束角度 | 指標結束 |

**變數關係**：指標位置相對於整個刻度範圍的比例

**子型別**：
- 基礎儀表盤
- 速度儀表盤
- 進度儀表盤
- 多標題儀表盤
- 等級儀表盤
- 時鐘儀表盤
- 汽車儀表盤

```javascript
option = {
  series: [{
    type: 'gauge',
    radius: '80%',
    startAngle: 200,
    endAngle: -20,
    min: 0,
    max: 100,
    splitNumber: 10,
    pointer: { length: '60%', width: 6 },
    axisLine: {
      lineStyle: {
        width: 20,
        color: [
          [0.3, '#47b262'],
          [0.7, '#fac858'],
          [1, '#eb5454']
        ]
      }
    },
    data: [{ value: 67, name: '進度' }],
    title: { offsetCenter: [0, '40%'] },
    detail: { valueAnimation: true, formatter: '{value}%' }
  }]
};
```

## 通用配置

### K線圖專屬配置

```javascript
series: [{
  type: 'candlestick',
  barWidth: '60%',
  itemStyle: {
    color: '#eb5454',        // 陽線（上漲）
    color0: '#47b262',       // 陰線（下跌）
    borderColor: '#eb5454',
    borderColor0: '#47b262'
  }
}]
```

### 雷達圖專屬配置

```javascript
radar: {
  indicator: [
    { name: '指標1', max: 100 },
    { name: '指標2', max: 100 }
  ],
  shape: 'polygon',
  splitNumber: 5,
  axisName: { color: '#333' },
  splitLine: { lineStyle: { color: '#ccc' } },
  splitArea: { areaStyle: { color: ['#fff', '#f5f5f5'] } }
}
```

### 儀表盤專屬配置

```javascript
series: [{
  type: 'gauge',
  radius: '75%',
  center: ['50%', '60%'],
  startAngle: 180,
  endAngle: 0,
  min: 0,
  max: 240,
  splitNumber: 12,
  pointer: {
    icon: 'path://M12.8,0.7l12,40.1H0.7L12.8,0.7z',
    length: '12%',
    width: 20,
    offsetCenter: [0, '-10%']
  },
  axisLine: { lineStyle: { width: 6 } },
  axisTick: { length: 12, lineStyle: { color: 'auto' } },
  splitLine: { length: 20, lineStyle: { color: 'auto' } },
  axisLabel: { color: '#464646', fontSize: 12, distance: -60 },
  detail: { valueAnimation: true, fontSize: 50, offsetCenter: [0, '70%'] }
}]
```

## 資料轉換

### 股票資料轉K線圖

```javascript
function toCandlestick(stockData) {
  return stockData.map(item => {
    return [
      item.open,    // 開盤
      item.close,   // 收盤
      item.low,     // 最低
      item.high     // 最高
    ];
  });
}
```

### 評估資料轉雷達圖

```javascript
function toRadarData(evaluation) {
  return {
    value: [
      evaluation.speed,
      evaluation.power,
      evaluation.function,
      evaluation.appearance,
      evaluation.economy
    ],
    name: evaluation.name
  };
}
```

## 注意事項

1. **K線圖**：確保OHLC資料順序正確，顏色配置要區分漲跌
2. **雷達圖**：指標數量建議5-8個，過多會導致圖形擁擠
3. **儀表盤**：使用分段顏色直觀展示進度/狀態
4. **大資料量**：K線圖超過1000條考慮使用dataZoom
5. **互動**：K線圖常配合MA均線使用

## 相關技能

- [echart-basic](../echart-basic/SKILL.md) - 基礎圖表
- [echart-multi](../echart-multi/SKILL.md) - 多圖組合（K線+成交量）
- [echart-advanced](../echart-advanced/SKILL.md) - 高階特性（dataZoom縮放）
