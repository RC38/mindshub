---
name: echart-relation
version: v1.0.0
author: skill-factory
parent: echart
description: ECharts 關係圖技能，掌握關係圖、桑基圖、樹圖、旭日圖等層級和網路關係資料的視覺化配置
tags: [echarts, graph, sankey, tree, sunburst, relation, network]
dependency:
  parent: echart
  requires: echart-basic
---

# EChart Relation Skill - 關係圖技能

## 任務目標

- **本 Skill 用於**：掌握關係型資料的視覺化（網路關係、層級結構、流量分佈）
- **核心能力**：
  - 關係圖：網路關係、組織結構
  - 桑基圖：流量守恆、流向分析
  - 樹圖：層級歸屬、目錄結構
  - 旭日圖：多級佔比、層級分佈
- **觸發條件**：展示網路關係、層級資料、流量資料時

## 圖表型別

### 關係圖 (Graph)

**展示資訊**：節點間的網路關係、權重連線

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| nodes | 節點陣列 | [{name, value, category, symbolSize}] |
| links/edges | 邊陣列 | [{source, target, value}] |
| categories | 分類陣列 | 節點的分組 |
| layout | 佈局演算法 | 'force'/'circular'/'none' |

**變數關係**：source-target 連線關係，value 表示權重

**子型別**：
- 力引導佈局圖 (force)
- 笛卡爾座標系關係圖
- 環形佈局圖
- 自動佈局關係圖
- 關係圖示籤隱藏重疊

```javascript
option = {
  series: [{
    type: 'graph',
    layout: 'force',
    nodes: [
      { name: 'Node1', value: 10, category: 0 },
      { name: 'Node2', value: 20, category: 1 }
    ],
    links: [
      { source: 'Node1', target: 'Node2', value: 5 }
    ],
    categories: [{ name: '類目1' }, { name: '類目2' }],
    force: {
      repulsion: 100,
      edgeLength: 50
    }
  }]
};
```

### 桑基圖 (Sankey)

**展示資訊**：流量從起點到終點的守恆關係

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| nodes | 節點陣列 | [{name}] |
| links | 邊陣列 | [{source, target, value}] |
| nodeAlign | 對齊方式 | 'left'/'right'/'justify' |

**變數關係**：流量守恆（流入=流出）

**子型別**：
- 水平桑基圖
- 垂直桑基圖
- 漸變色邊桑基圖
- 層級自定義樣式桑基圖

```javascript
option = {
  series: [{
    type: 'sankey',
    layout: 'none',
    orient: 'horizontal',
    nodeAlign: 'left',
    nodes: [
      { name: '入口1' },
      { name: '出口1' },
      { name: '出口2' }
    ],
    links: [
      { source: '入口1', target: '出口1', value: 100 },
      { source: '入口1', target: '出口2', value: 50 }
    ],
    lineStyle: { color: 'gradient' }
  }]
};
```

### 樹圖 (Tree)

**展示資訊**：嚴格的父子層級關係

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| data | 樹節點物件 | {name, children: [...]} |
| orient | 展開方向 | 'horizontal'/'vertical'/'radial' |
| symbol | 節點形狀 | 'circle'/'rect'/'roundRect' |
| label | 標籤配置 | 節點文字樣式 |

**變數關係**：嚴格的樹形父子歸屬關係

**子型別**：
- 從左到右樹圖
- 從上到下樹圖
- 徑向樹圖
- 折線樹圖

```javascript
option = {
  series: [{
    type: 'tree',
    orient: 'horizontal',
    data: [{
      name: 'Root',
      children: [
        { name: 'Branch1', children: [{ name: 'Leaf1' }] },
        { name: 'Branch2' }
      ]
    }]
  }]
};
```

### 旭日圖 (Sunburst)

**展示資訊**：多層級佔比資料，從內到外的包含關係

**變數**：
| 變數 | 型別 | 說明 |
|-----|------|-----|
| data | 旭日節點陣列 | [{name, value, children}] |
| radius | 半徑 | [內半徑, 外半徑] |
| label | 標籤配置 | 扇區標籤樣式 |
| levels | 層級配置 | 每層的半徑、標籤設定 |

**變數關係**：從內到外的包含佔比關係

**子型別**：
- 基礎旭日圖
- 圓角旭日圖
- 單色旭日圖
- 標籤旋轉旭日圖

```javascript
option = {
  series: [{
    type: 'sunburst',
    radius: ['20%', '80%'],
    data: [{
      name: 'Root',
      value: 100,
      children: [
        { name: 'Part1', value: 60, children: [{ name: 'Detail1', value: 30 }] },
        { name: 'Part2', value: 40 }
      ]
    }],
    label: { rotate: 'radial' }
  }]
};
```

## 通用配置

### 力引導佈局配置

```javascript
force: {
  initLayout: 'circular',  // 初始化佈局
  repulsion: 100,           // 節點斥力
  gravity: 0.1,             // 重心引力
  edgeLength: [50, 200],    // 邊的理想長度
  layoutAnimation: true     // 佈局動畫
}
```

### 節點樣式

```javascript
itemStyle: {
  color: '#5470C6',
  borderColor: '#fff',
  borderWidth: 2,
  shadowBlur: 10,
  shadowColor: 'rgba(0,0,0,0.3)'
}
```

### 邊樣式

```javascript
lineStyle: {
  color: '#ccc',
  width: 1,
  curveness: 0.3,      // 彎曲度
  opacity: 0.6
}
```

## 資料轉換

### 從樹形資料轉換

```javascript
// 樹形 -> 旭日圖
function treeToSunburst(data) {
  return {
    name: data.name,
    value: data.value || data.children?.reduce((sum, c) => sum + c.value, 0),
    children: data.children?.map(treeToSunburst)
  };
}
```

### 從鄰接錶轉換

```javascript
// 鄰接表 -> 關係圖節點和邊
function adjacencyToGraph(adjList) {
  const nodes = [];
  const links = [];
  Object.keys(adjList).forEach(source => {
    nodes.push({ name: source });
    adjList[source].forEach(target => {
      nodes.push({ name: target });
      links.push({ source, target });
    });
  });
  return { nodes, links };
}
```

## 注意事項

1. **力引導佈局**：大資料量時考慮關閉佈局動畫或減少迭代次數
2. **桑基圖**：確保流量守恆（可選中節點編輯）
3. **樹圖**：資料必須是嚴格的樹形結構（無環）
4. **旭日圖**：內層值應該等於外層所有子節點之和
5. **效能**：超過500節點考慮使用 canvas 渲染器

## 相關技能

- [echart-basic](../echart-basic/SKILL.md) - 基礎圖表
- [echart-multi](../echart-multi/SKILL.md) - 多圖組合（聯動）
- [echart-geo](../echart-geo/SKILL.md) - 地理圖（關係圖+地圖）
