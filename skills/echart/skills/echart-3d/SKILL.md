---
name: echart-3d
version: v1.0.0
author: skill-factory
parent: echart
description: ECharts 3D圖表技能，掌握3D柱狀圖、3D散點圖、3D曲面等三維視覺化，用於立體對比、空間分佈和曲面分析
tags: [echarts, bar3D, scatter3D, surface3D, line3D, 3D, visualization]
dependency:
  parent: echart
  requires: echart-basic
---

# EChart 3D Skill - 3D圖表技能

## 任務目標

- **本 Skill 用於**：掌握三維資料視覺化（立體對比、空間分佈、曲面分析）
- **核心能力**：
  - 3D柱狀圖：三維柱形對比
  - 3D散點圖：空間三維分佈
  - 3D曲面：連續曲面擬合
  - 3D路徑圖：空間軌跡
- **觸發條件**：需要展示三維資料或立體視覺化時

## 圖表型別

### 3D柱狀圖 (Bar3D)

**展示資訊**：三維座標系中的柱形對比

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| grid3D | 三維座標系 | x、y、z軸配置 |
| xAxis3D | 類目/數值軸 | x軸 |
| yAxis3D | 類目/數值軸 | y軸 |
| zAxis3D | 數值軸 | z軸（高度） |
| series.data | 三維陣列 | [x, y, z] |

**變數關係**：x、y確定底面位置，z確定高度

**子型別**：
- 基礎3D柱狀圖
- 全球人口3D柱狀圖
- 3D堆疊柱狀圖
- 透明3D柱狀圖
- 3D柱狀圖+地球

```javascript
option = {
  grid3D: {
    viewControl: { projection: 'perspective', autoRotateAngle: 30 },
    light: { main: { intensity: 1.2 }, ambient: { intensity: 0.3 } }
  },
  xAxis3D: { type: 'category', data: ['A', 'B', 'C'] },
  yAxis3D: { type: 'category', data: ['X', 'Y', 'Z'] },
  zAxis3D: { type: 'value', max: 100 },
  series: [{
    type: 'bar3D',
    data: [
      [0, 0, 50], [1, 0, 70], [2, 0, 60],
      [0, 1, 40], [1, 1, 80], [2, 1, 65]
    ],
    shading: 'realistic',
    itemStyle: { color: '#5470C6', opacity: 0.8 }
  }]
};
```

### 3D散點圖 (Scatter3D)

**展示資訊**：三維空間中的點分佈

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| grid3D | 三維座標系 | 座標軸配置 |
| series.data | 四維陣列 | [x, y, z, value] |
| symbolSize | 數值/函式 | 點的大小 |
| visualMap | 視覺對映 | 顏色編碼第四維 |

**變數關係**：x、y、z確定位置，value編碼顏色/大小

**子型別**：
- 基礎3D散點圖
- 全球人口3D散點圖
- 正交投影3D散點圖
- 3D散點+散點矩陣

```javascript
option = {
  grid3D: { viewControl: { projection: 'orthographic' } },
  xAxis3D: { type: 'value', name: 'X' },
  yAxis3D: { type: 'value', name: 'Y' },
  zAxis3D: { type: 'value', name: 'Z' },
  series: [{
    type: 'scatter3D',
    data: [
      [10, 20, 30, 100],
      [15, 25, 35, 80],
      [20, 15, 40, 120]
    ],
    symbolSize: function(data) { return data[3] / 20; },
    visualMap: { min: 0, max: 150, dimension: 3 }
  }]
};
```

### 3D曲面 (Surface)

**展示資訊**：連續曲面的擬合和展示

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| grid3D | 三維座標系 | 座標系配置 |
| series.type | 'surface' | 曲面圖 |
| series.data | 三維矩陣 | height Matrix |
| series.surface公式 | 函式 | 自定義曲面方程 |

**變數關係**：x、y確定平面位置，z確定高度

**子型別**：
- 引數曲面
- 球面引數曲面
- 金屬曲面
- 玫瑰曲面
- 波形曲面

```javascript
option = {
  grid3D: { viewControl: { autoRotate: true } },
  xAxis3D: { type: 'value', min: -3, max: 3 },
  yAxis3D: { type: 'value', min: -3, max: 3 },
  zAxis3D: { type: 'value', min: -3, max: 3 },
  series: [{
    type: 'surface',
    parametric: true,
    equation: {
      x: function(u, v) { return Math.sin(u) * Math.sin(v); },
      y: function(u, v) { return Math.sin(u) * Math.cos(v); },
      z: function(u, v) { return Math.cos(u); }
    },
    uStep: 30,
    vStep: 30,
    itemStyle: { color: '#5470C6', opacity: 0.8 }
  }]
};
```

### 3D路徑圖 (Lines3D)

**展示資訊**：三維空間中的軌跡路徑

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| globe3D | 地球座標系 | 用於地球軌跡 |
| series.type | 'lines3D' | 3D路徑圖 |
| series.data | 陣列 | [{coords: [[lng1,lat1,h1], [lng2,lat2,h2]]}] |

**變數關係**：起點到終點的三維軌跡

**子型別**：
- 地球航線圖
- 3D路徑動畫
- 飛線效果

```javascript
option = {
  globe3D: {
    baseTexture: 'world.jpg',
    heightTexture: 'height.jpg',
    shading: 'realistic',
    light: { main: { intensity: 0.8 } }
  },
  series: [{
    type: 'lines3D',
    coordinateSystem: 'globe3D',
    data: [{
      name: 'Flight',
      coords: [
        [116.46, 39.92, 0],
        [-74.0, 40.7, 0]
      ],
      lineStyle: { color: '#5470C6', width: 3 }
    }]
  }]
};
```

## 通用配置

### 三維座標系配置

```javascript
grid3D: {
  viewControl: {
    projection: 'perspective',   // 'perspective' | 'orthographic'
    autoRotate: true,             // 自動旋轉
    autoRotateSpeed: 30,          // 旋轉速度
    distance: 100,                // 視角距離
    alpha: 40,                    // 視角繞x軸旋轉角度
    beta: 40,                     // 視角繞y軸旋轉角度
    center: [0, 0, 0]             // 中心點
  },
  light: {
    main: {
      intensity: 1.2,
      shadow: true,
      shadowQuality: 'high'
    },
    ambient: { intensity: 0.3 }
  },
  axisLine: { lineStyle: { color: '#ccc' } },
  axisLabel: { textStyle: { color: '#333' } },
  splitLine: { lineStyle: { color: '#eee' } }
}
```

### 材質和渲染

```javascript
itemStyle: {
  color: '#5470C6',
  opacity: 0.8,
  borderColor: '#fff',
  borderWidth: 1
},
shading: 'realistic',           // 'realistic' | 'lambert' | 'color' | 'normal'
realisticMaterial: {
  roughness: 0.6,
  metalness: 0.1
}
```

## 注意事項

1. **ECharts GL**：3D圖表需要引入 ECharts GL 元件
2. **效能**：3D圖表效能消耗大，資料量過大會卡頓
3. **視角控制**：使用viewControl配置互動
4. **光照**：複雜場景需要配置光源避免黑麵
5. **相容**：部分瀏覽器可能不支援WebGL

## 相關技能

- [echart-basic](../echart-basic/SKILL.md) - 基礎圖表
- [echart-geo](../echart-geo/SKILL.md) - 地理圖
- [echart-multi](../echart-multi/SKILL.md) - 多圖組合
