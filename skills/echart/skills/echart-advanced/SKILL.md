---
name: echart-advanced
version: v1.0.0
author: skill-factory
parent: echart
description: ECharts 高階特性技能，掌握資料集、資料區域縮放、自定義系列等高階功能，用於資料處理、互動探索和定製渲染
tags: [echarts, dataset, dataZoom, custom, series, advanced]
dependency:
  parent: echart
  requires: echart-basic
---

# EChart Advanced Skill - 高階特性技能

## 任務目標

- **本 Skill 用於**：掌握ECharts高階特性（資料處理、互動探索、定製渲染）
- **核心能力**：
  - 資料集(Dataset)：行列資料對映、資料變換
  - 資料區域縮放(DataZoom)：滑塊縮放、框選縮放
  - 自定義系列(Custom Series)：自定義渲染邏輯
  - 富文字(Rich Text)：豐富的文字樣式
- **觸發條件**：處理複雜資料、需要深度互動、定製渲染時

## 圖表型別

### 資料集 (Dataset)

**展示資訊**：結構化表格資料的視覺化

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| dimensions | 維度定義 | 列名和型別 |
| source | 資料來源 | 陣列/物件陣列 |
| encode | 編碼對映 | 指定x/y/series對映 |
| transform | 資料變換 | filter/sort/aggregate |

**變數關係**：行列資料到圖表的對映關係

```javascript
option = {
  dataset: {
    dimensions: ['product', 'sales', 'profit'],
    source: [
      { product: 'A', sales: 120, profit: 30 },
      { product: 'B', sales: 200, profit: 50 },
      { product: 'C', sales: 150, profit: 40 }
    ]
  },
  xAxis: { type: 'category', name: 'Product', encode: { x: 'product' } },
  yAxis: { type: 'value', name: 'Value' },
  series: [
    { type: 'bar', encode: { y: 'sales' } },
    { type: 'line', encode: { y: 'profit' } }
  ]
};
```

### 資料變換

```javascript
dataset: [{
  source: [...]  // 原始資料
}, {
  transform: {
    type: 'filter',
    config: { dimension: 3, '>=': 100 }
  }
}, {
  transform: {
    type: 'sort',
    config: { dimension: 1, order: 'desc' }
  }
}, {
  transform: {
    type: 'aggregate',
    config: {
      dimensions: ['category'],
      groups: 'category',
      aggregate: 'sum'
    }
  }
}]
```

### 資料區域縮放 (DataZoom)

**展示資訊**：資料的區域性放大和瀏覽

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| start | 起始位置 | 0-100百分比 |
| end | 結束位置 | 0-100百分比 |
| type | 型別 | 'inside'/'slider'/'rect' |
| xAxisIndex | 繫結軸 | 關聯的x軸索引 |
| yAxisIndex | 繫結軸 | 關聯的y軸索引 |

**變數關係**：縮放範圍與原始資料的對映

**子型別**：
- 內建滾輪縮放(inside)
- 滑塊縮放(slider)
- 框選手動選擇(rect)
- 多軸縮放
- 時間軸縮放

```javascript
option = {
  dataZoom: [
    {
      type: 'inside',
      xAxisIndex: 0,
      start: 0,
      end: 100
    },
    {
      type: 'slider',
      xAxisIndex: 0,
      start: 20,
      end: 80,
      height: 20,
      bottom: 10
    }
  ],
  xAxis: { type: 'category', data: [...] },
  yAxis: { type: 'value' },
  series: [{ type: 'line', data: [...] }]
};
```

### 自定義系列 (Custom Series)

**展示資訊**：完全自定義的渲染邏輯

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| type | 'custom' | 自定義型別 |
| renderItem | 渲染函式 | 返回圖形物件 |
| encode | 編碼對映 | 資料到座標的對映 |
| data | 資料陣列 | 渲染使用的資料 |

**變數關係**：資料到自定義圖形的對映

**子型別**：
- 自定義柱狀圖趨勢線
- 自定義誤差範圍
- 甘特圖
- 火焰圖
- 風向圖
- 六邊形分箱圖

```javascript
series: [{
  type: 'custom',
  renderItem: function(params, api) {
    var xValue = api.value(0);
    var yValue = api.value(1);
    var point = api.coord([xValue, yValue]);
    return {
      type: 'rect',
      shape: { x: point[0], y: point[1], width: 20, height: 40 },
      style: { fill: '#5470C6' }
    };
  },
  data: [
    [0, 50], [1, 70], [2, 60]
  ]
}]
```

### 富文字 (Rich Text)

**展示資訊**：豐富的文字樣式和佈局

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| rich | 富文字定義 | 樣式名稱和配置 |
| textStyle | 文字樣式 | 使用rich引用 |
| formatter | 格式化 | 富文字模板 |

```javascript
option = {
  series: [{
    type: 'pie',
    radius: ['30%', '70%'],
    label: {
      formatter: [
        '{name|{b}}',
        '{value|{c}}',
        '{percent|{d}%}'
      ].join('\n'),
      rich: {
        name: { fontSize: 14, color: '#333', fontWeight: 'bold' },
        value: { fontSize: 20, color: '#5470C6' },
        percent: { fontSize: 12, color: '#999' }
      }
    }
  }]
};
```

## 通用配置

### DataZoom 詳細配置

```javascript
dataZoom: [{
  type: 'slider',
  show: true,
  xAxisIndex: [0, 1],           // 關聯多個軸
  start: 0,
  end: 100,
  height: 30,
  bottom: 50,
  borderColor: '#ccc',
  fillerColor: 'rgba(84,112,198,0.2)',
  handleStyle: {
    color: '#5470C6',
    borderColor: '#5470C6'
  },
  textStyle: { color: '#333' },
  dataBackground: {
    lineStyle: { color: '#ccc' },
    areaStyle: { color: '#eee' }
  },
  selectedDataBackground: {
    lineStyle: { color: '#5470C6' },
    areaStyle: { color: 'rgba(84,112,198,0.2)' }
  }
}]
```

### 自定義系列 renderItem 引數

```javascript
renderItem: function(params, api) {
  // params: { context, batch, info }
  // api.value(dim): 獲取資料值
  // api.coord([x, y]): 資料轉畫素座標
  // api.size([width, height]): 資料寬度轉畫素
  // api.theme: 主題配置
  // api.getWidth(): 畫布寬度
  // api.getHeight(): 畫布高度

  var categoryIndex = api.value(0);
  var value = api.value(1);
  var point = api.coord([categoryIndex, value]);

  return {
    type: 'group',
    children: [{
      type: 'rect',
      shape: { x: point[0], y: point[1], width: 30, height: 60 },
      style: { fill: '#5470C6' }
    }]
  };
}
```

## 資料轉換

### Dataset encode 對映

```javascript
encode: {
  x: 0,                        // 第一列對映到x軸
  y: [1, 2],                   // 第2、3列對映到y軸（多系列）
  tooltip: [0, 1, 2],          // 提示框顯示這些列
  legend: 1,                   // 圖例使用第2列
  seriesName: [0, 1]           // 系列名稱
}
```

### 資料變換鏈式呼叫

```javascript
dataset: [{
  id: 'raw',
  source: rawData
}, {
  id: 'filtered',
  fromDatasetId: 'raw',
  transform: { type: 'filter', config: { dimension: 'year', '>=': 2020 } }
}, {
  id: 'sorted',
  fromDatasetId: 'filtered',
  transform: { type: 'sort', config: { dimension: 'sales', order: 'desc' } }
}]
```

## 注意事項

1. **Dataset效能**：複雜變換可能影響效能，大資料量測試後再使用
2. **DataZoom聯動**：多個圖表需要設定dataZoomIndex並繫結同一軸
3. **自定義系列**：renderItem必須返回ZRender圖形物件
4. **Canvas渲染**：自定義系列預設使用canvas渲染
5. **除錯**：使用console.log輸出api.value()檢查資料對映

## 相關技能

- [echart-basic](../echart-basic/SKILL.md) - 基礎圖表
- [echart-multi](../echart-multi/SKILL.md) - 多圖組合（聯動）
- [echart-finance](../echart-finance/SKILL.md) - 金融圖（K線圖+DataZoom）
