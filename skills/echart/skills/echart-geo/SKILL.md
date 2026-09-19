---
name: echart-geo
version: v1.0.0
author: skill-factory
parent: echart
description: ECharts 地理圖技能，掌握地圖、3D地球、航線圖等地理座標視覺化，用於區域分析、人口分佈和空間分佈展示
tags: [echarts, map, geo, globe, flight, geographic, visualization]
dependency:
  parent: echart
  requires: echart-basic
---

# EChart Geo Skill - 地理圖技能

## 任務目標

- **本 Skill 用於**：掌握地理座標資料視覺化（區域分析、空間分佈、航線軌跡）
- **核心能力**：
  - 地圖：區域資料、地理分割槽
  - 3D地球：全球視角、立體分佈
  - 航線圖：路徑軌跡、連線關係
- **觸發條件**：展示地理位置相關資料時

## 圖表型別

### 地圖 (Map)

**展示資訊**：地理區域上的資料分佈

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| geo | 地理座標系 | 地圖配置 |
| series.data | 陣列 | [{name, value}] |
| map | 地圖名稱 | 對應GeoJSON |
| selectedMode | 選擇模式 | 'single'/'multiple' |

**變數關係**：地理區域名稱與數值的對映

**子型別**：
- 中國地圖/省份地圖
- 世界地圖
- 等值區劃圖（Choropleth）
- 散點地圖
- 城市氣泡圖
- 自定義地圖投影

```javascript
// 註冊地圖
echarts.registerMap('china', chinaGeoJSON);

option = {
  geo: {
    map: 'china',
    roam: true,                    // 支援縮放拖拽
    label: { show: true },
    itemStyle: { areaColor: '#eee', borderColor: '#ccc' },
    emphasis: {
      itemStyle: { areaColor: '#ffd700' },
      label: { show: true }
    }
  },
  series: [{
    type: 'map',
    geoIndex: 0,
    data: [
      { name: '北京', value: 100 },
      { name: '上海', value: 80 },
      { name: '廣州', value: 60 }
    ]
  }]
};
```

### 散點地圖 (Scatter + Geo)

**展示資訊**：地理位置上的點分佈

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| geo | 地理座標系 | 地圖配置 |
| series.type | 'scatter' | 散點圖 |
| series.data | 陣列 | [longitude, latitude, value] |
| symbolSize | 數值/函式 | 點的大小 |

**變數關係**：經緯度確定位置，value編碼大小/顏色

**子型別**：
- 基礎散點地圖
- 漣漪特效散點地圖（effectScatter）
- 氣泡大小地圖
- 顏色編碼地圖

```javascript
option = {
  geo: { map: 'china', roam: true },
  series: [{
    type: 'effectScatter',
    coordinateSystem: 'geo',
    data: [
      { name: '北京', value: [116.46, 39.92, 100] },
      { name: '上海', value: [121.48, 31.22, 80] }
    ],
    symbolSize: function(val) { return val[2] / 10; },
    showEffectOn: 'render',
    rippleEffect: { brushType: 'stroke', scale: 3 }
  }]
};
```

### 熱力地圖 (Heatmap + Geo)

**展示資訊**：地理區域的熱力分佈

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| geo | 地理座標系 | 地圖配置 |
| series.type | 'heatmap' | 熱力圖 |
| series.data | 陣列 | [lng, lat, value] |

**變數關係**：經緯度密度分佈

**子型別**：
- 城市熱力分佈
- 人口密度熱力圖

```javascript
option = {
  geo: { map: 'china', roam: true, zoom: 1.2 },
  series: [{
    type: 'heatmap',
    coordinateSystem: 'geo',
    data: [
      [116.46, 39.92, 100],
      [121.48, 31.22, 80],
      [113.23, 23.16, 60]
    ]
  }]
};
```

### 航線圖 (Lines)

**展示資訊**：起點到終點的路徑軌跡

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| series.type | 'lines' | 路徑圖 |
| series.data | 陣列 | [{coords: [[lng1,lat1], [lng2,lat2]], value}] |
| polyline | 布林 | 是否為折線（false=曲線） |
| effect | 特效配置 | 動畫效果 |

**變數關係**：起點到終點的弧線連線

**子型別**：
- 基礎航線圖
- 3D地球航線圖
- 顏色漸變航線圖
- 動畫特效航線圖

```javascript
option = {
  geo: { map: 'china', roam: true },
  series: [{
    type: 'lines',
    coordinateSystem: 'geo',
    data: [{
      name: '北京->上海',
      coords: [[116.46, 39.92], [121.48, 31.22]],
      lineStyle: { color: '#5470C6', width: 2, curveness: 0.3 },
      effect: { show: true, period: 4, trailLength: 0.3 }
    }]
  }]
};
```

### 3D地球 (Globe)

**展示資訊**：全球視角的立體地理資料

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| series.type | 'globe' | 3D地球 |
| globeRadius | 數值 | 地球半徑 |
| baseTexture | 紋理 | 地球表面紋理 |
| layers | 圖層配置 | 大氣層、光照等 |

**變數關係**：三維球面上的資料疊加

**子型別**：
- 基礎3D地球
- 大氣層顯示
- 等值線動畫地球
- 地形位移地球
- 3D柱狀圖地球

```javascript
option = {
  series: [{
    type: 'globe',
    globeRadius: 100,
    baseTexture: 'world.jpg',
    heightTexture: 'elevation.tif',
    shading: 'realistic',
    atmosphere: { show: true, color: '#fff', intensity: 0.5 },
    layers: [{
      type: 'scatter3D',
      coordinateSystem: 'geo3D',
      data: [[116.46, 39.92, 100]]
    }]
  }]
};
```

## 通用配置

### 地理座標系配置

```javascript
geo: {
  map: 'world',                   // 地圖名稱
  roam: true,                      // 是否開啟滑鼠縮放和平移漫遊
  zoom: 1,                         // 當前縮放級別
  center: [0, 0],                 // 中心點經緯度
  scaleLimit: { min: 1, max: 8 }, // 縮放限制
  label: {
    show: false,                   // 是否顯示標籤
    color: '#333'
  },
  itemStyle: {
    areaColor: '#eee',             // 區域顏色
    borderColor: '#ccc',           // 邊界顏色
    borderWidth: 1
  },
  emphasis: {                      // 高亮狀態
    itemStyle: { areaColor: '#ffd700' },
    label: { show: true }
  }
}
```

### 註冊地圖

```javascript
// 內建地圖
 echarts.registerMap('china', chinaGeoJSON);
 echarts.registerMap('world', worldGeoJSON);

// 從URL載入
fetch('https://example.com/china.json')
  .then(res => res.json())
  .then(data => echarts.registerMap('china', data));
```

## 資料轉換

### 經緯度資料轉地圖散點

```javascript
function toGeoScatter(locations) {
  return locations.map(loc => ({
    name: loc.name,
    value: [loc.lng, loc.lat, loc.value || 1]
  }));
}
```

### 行政區劃資料轉等值區劃圖

```javascript
function toChoropleth(districtData) {
  return districtData.map(d => ({
    name: d.districtName,
    value: d.value
  }));
}
```

## 注意事項

1. **地圖註冊**：使用前必須註冊對應GeoJSON
2. **座標系**：geo3D用於3D地球散點/柱狀/航線
3. **資料格式**：經緯度順序是 [lng, lat] 不是 [lat, lng]
4. **漫遊限制**：設定scaleLimit防止過度縮放
5. **效能**：大資料量散點使用 effectScatter 而非普通 scatter

## 相關技能

- [echart-basic](../echart-basic/SKILL.md) - 基礎圖表
- [echart-3d](../echart-3d/SKILL.md) - 3D圖表
- [echart-multi](../echart-multi/SKILL.md) - 多圖組合（地圖+散點+航線疊加）
