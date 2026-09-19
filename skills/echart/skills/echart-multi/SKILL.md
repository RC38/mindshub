---
name: echart-multi
version: v1.0.0
author: skill-factory
parent: echart
description: ECharts 多圖組合技能，掌握grid、polar、timeline、聯動等組合圖表技術，用於多維度資料對比和複雜視覺化場景
tags: [echarts, grid, polar, timeline, connect, combination, multi-chart]
dependency:
  parent: echart
  requires: echart-basic
---

# EChart Multi Skill - 多圖組合技能

## 任務目標

- **本 Skill 用於**：掌握多圖表組合技術（座標系疊加、時間軸聯動、圖表聯動）
- **核心能力**：
  - Grid組合：多2D圖表並排/疊加
  - Polar組合：極座標下多圖表疊加
  - Timeline組合：時間軸驅動的動態切換
  - 聯動(Connect)：多圖表同步操作
- **觸發條件**：需要展示多維度對比、複雜視覺化、動態資料時

## 圖表型別

### Grid 組合

**展示資訊**：多個2D圖表共享座標系或並排顯示

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| grid | 座標系陣列 | 多個grid區域 |
| xAxis | 多軸配置 | 多個x軸 |
| yAxis | 多軸配置 | 多個y軸 |
| series | 多系列 | 分佈在不同grid |

**變數關係**：共享或獨立的座標系統

**子型別**：
- 上下排列（多行grid）
- 左右排列（多列grid）
- 共享x軸的雙y軸圖
- 折線柱狀混合圖
- 多X軸圖

```javascript
option = {
  grid: [
    { left: '10%', right: '10%', top: '10%', height: '35%' },
    { left: '10%', right: '10%', top: '55%', height: '35%' }
  ],
  xAxis: [
    { type: 'category', data: [...], gridIndex: 0 },
    { type: 'category', data: [...], gridIndex: 1 }
  ],
  yAxis: [
    { type: 'value', gridIndex: 0 },
    { type: 'value', gridIndex: 1 }
  ],
  series: [
    { type: 'line', xAxisIndex: 0, yAxisIndex: 0, data: [...] },
    { type: 'bar', xAxisIndex: 1, yAxisIndex: 1, data: [...] }
  ]
};
```

### Polar 組合

**展示資訊**：極座標下的多圖表疊加

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| polar | 極座標系 | 極座標配置 |
| radiusAxis | 徑向軸 | 半徑軸 |
| angleAxis | 角度軸 | 角度軸 |
| series | 多個系列 | 疊加在同一極座標 |

**變數關係**：共享極座標中心

**子型別**：
- 柱狀圖+折線圖+餅圖疊加
- 極座標散點圖
- 雷達圖（polar的特殊形式）
- 南極魚玫瑰圖（極座標面積圖）

```javascript
option = {
  polar: { center: ['50%', '50%'], radius: '80%' },
  radiusAxis: { max: 100 },
  angleAxis: {
    type: 'category',
    data: ['A', 'B', 'C', 'D', 'E'],
    startAngle: 90
  },
  series: [
    {
      type: 'bar',
      data: [80, 60, 90, 70, 50],
      coordinateSystem: 'polar',
      name: '系列1',
      stack: 'group'
    },
    {
      type: 'line',
      data: [60, 40, 70, 50, 30],
      coordinateSystem: 'polar',
      name: '系列2'
    }
  ]
};
```

### Timeline 時間軸

**展示資訊**：時間軸驅動的資料動態切換

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| timeline | 時間軸配置 | 自動播放控制 |
| options | 選項陣列 | 每個時間點的配置 |
| currentIndex | 當前索引 | 當前顯示的時間點 |

**變數關係**：時間點與資料配置的對映

**子型別**：
- 動態折線圖（資料隨時間變化）
- 動態柱狀圖排名
- 動態地圖資料
- 自定義時間軸

```javascript
option = {
  baseOption: {
    title: { text: '動態資料展示' },
    xAxis: { type: 'category', data: ['A', 'B', 'C', 'D'] },
    yAxis: { type: 'value' },
    series: [{ type: 'bar', data: [] }]
  },
  options: [
    { series: [{ data: [120, 200, 150, 80] }] },
    { series: [{ data: [100, 180, 190, 120] }] },
    { series: [{ data: [140, 220, 170, 100] }] }
  ],
  timeline: {
    data: ['2020', '2021', '2022'],
    autoPlay: true,
    playInterval: 2000,
    loop: true
  }
};
```

### 聯動 (Connect)

**展示資訊**：多個圖表同步操作

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| echarts.connect | 連線組 | 將多個圖表關聯 |
| group | 組標識 | 連線組的ID |

**變數關係**：同一組的圖表共享互動狀態

**子型別**：
- 刷選聯動
- 縮放聯動
- 提示框聯動
- 圖例聯動

```javascript
// 方式1：直接連線
echarts.connect('dashboard');

// 方式2：使用bindGroup
var chart1 = echarts.init(document.getElementById('chart1'));
var chart2 = echarts.init(document.getElementById('chart2'));
chart1.group = 'dashboard';
chart2.group = 'dashboard';
echarts.connect('dashboard');

// 斷開連線
echarts.disConnect('dashboard');
```

### 疊加 (Overlay)

**展示資訊**：多個系列疊加在同一座標系

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| series | 系列陣列 | 多個系列 |
| xAxisIndex | 軸索引 | 共享x軸 |
| yAxisIndex | 軸索引 | 共享y軸 |

**變數關係**：共享座標軸的多個資料系列

```javascript
option = {
  xAxis: { type: 'category', data: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'] },
  yAxis: { type: 'value' },
  series: [
    {
      type: 'bar',
      data: [100, 200, 150, 80, 120],
      barWidth: '40%'
    },
    {
      type: 'line',
      data: [120, 180, 160, 90, 110],
      smooth: true,
      itemStyle: { color: '#eb5454' }
    },
    {
      type: 'scatter',
      symbolSize: 15,
      data: [[1, 170], [3, 165]],
      itemStyle: { color: '#5470C6' }
    }
  ]
};
```

## 多圖佈局方案

### 上下佈局

```javascript
grid: [
  { top: '5%', height: '40%' },   // 上圖
  { top: '55%', height: '40%' }   // 下圖
]
```

### 左右佈局

```javascript
grid: [
  { left: '5%', width: '43%' },   // 左圖
  { right: '5%', width: '43%' }   // 右圖
]
```

### 複雜佈局

```javascript
grid: [
  { left: '5%', top: '5%', width: '60%', height: '40%' },      // 主圖
  { right: '5%', top: '5%', width: '30%', height: '40%' },    // 側邊圖
  { left: '5%', top: '55%', width: '85%', height: '40%' }      // 底部大圖
]
```

## 通用配置

### 連線組配置

```javascript
// 連線多個圖表
echarts.connect('myGroup');

// 取消連線
echarts.disConnect('myGroup');

// 獲取已連線圖表列表
echarts.getConnected('myGroup');
```

### Axis Pointer 聯動

```javascript
tooltip: {
  trigger: 'axis',
  axisPointer: {
    type: 'cross',              // 'line' | 'shadow' | 'cross'
    crossStyle: { color: '#999' }
  }
}

axisPointer: {
  link: [{ xAxisIndex: 'all' }],
  label: { backgroundColor: '#333' }
}
```

## 注意事項

1. **Grid重疊**：避免grid區域重疊導致渲染問題
2. **座標軸唯一性**：每個series必須指定xAxisIndex和yAxisIndex
3. **Polar限制**：極座標下某些圖表型別不支援
4. **Timeline資料**：確保每個時間點資料格式一致
5. **聯動效能**：過多聯動圖表可能影響效能

## 相關技能

- [echart-basic](../echart-basic/SKILL.md) - 基礎圖表
- [echart-finance](../echart-finance/SKILL.md) - 金融圖（K線+成交量組合）
- [echart-geo](../echart-geo/SKILL.md) - 地理圖（地圖+散點+航線組合）
- [echart-advanced](../echart-advanced/SKILL.md) - 高階特性（DataZoom聯動）
