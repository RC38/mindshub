---
name: analytics-visualization
display_name: Analytics Visualization（多維視覺化呈現）
version: 1.0.1
description: Use when the user needs multi-dimensional data visualization, chart selection guidance, or interactive presentation patterns.
tags: [visualization, charting, plotly, dashboard, data-presentation]
---

# Analytics Visualization

## 任務目標
- 本 Skill 用於：掌握複雜資料的多維度視覺化呈現
- 能力包含：多維度變數展示、圖表選型、互動設計、視覺化原則
- 觸發條件：需要展示多維度資料、呈現分析結果時

## 適用場景
- 需要把多維資料壓縮成容易理解的圖表
- 需要在趨勢、對比、分佈、關係和路徑之間選圖
- 需要做互動式圖表或分析儀表盤

## 核心原則

### 視覺化黃金法則
```
1. 明確視覺化目標（比較、趨勢、分佈、關係、佔比）
2. 選擇適合資料型別的圖表
3. 減少視覺干擾，突出關鍵資訊
4. 引導讀者關注重點
5. 提供足夠的上下文幫助理解
```

### 圖表選擇決策樹
```
資料維度數量
    │
    ├── 1維（單一變數）→ 折線圖、柱狀圖
    │
    ├── 2維（兩個變數）→ 散點圖、氣泡圖
    │
    ├── 3維（三個變數）→ 3D散點圖、熱力圖
    │
    └── 多維（4+變數）→ 雷達圖、平行座標、桑基圖
                            ↓
                    考慮降維或分面展示
```

---

## 圖表實現引擎與 ECharts 工具族整合

本技能專注於「**圖表選型決策與維度表達心智**」。在具體代碼實現層面，強烈推薦與專屬工具技能協同：
- **Web 前端 / 互動大屏 / 獨立 HTML 報表**：優先調用 `tool/echart` 技能族（Apache ECharts 原生支援高性能渲染與豐富交互）。
- **Python Notebook / 快速探索性分析（EDA）**：使用 Plotly / Seaborn。

### 業務選型到 ECharts 子技能映射矩陣

| 業務分析目的 | 推薦圖表 | 優先調用之 ECharts 技能 | 典型應用場景 |
|:---|:---|:---|:---|
| **趨勢對比 / 總量佔比** | 折線圖、柱狀圖、堆疊圖、餅圖 | `tool/echart/skills/echart-basic` | 銷售額走勢、品類份額佔比、月度對比 |
| **業務流向 / 轉化層級** | 桑基圖、樹圖、旭日圖 | `tool/echart/skills/echart-relation` | 用戶流失漏斗、資金流向、組織架構成本 |
| **指標波動 / 關聯分佈** | 熱力圖、盒須圖（箱線圖）、平行座標 | `tool/echart/skills/echart-statistics` | 用戶活躍時段矩陣、價格帶分佈、多指標異常 |
| **用戶畫像 / KPI 監控** | 雷達圖、儀表盤、K線圖 | `tool/echart/skills/echart-finance` | VIP畫像評分、業績目標達成率、金融走勢 |
| **綜合大屏 / 多維聯動** | 多圖 Grid、Timeline、數據聯動 | `tool/echart/skills/echart-multi` | 決策層綜合看板、時間軸回放看板 |

### 數據分析橋接：Pandas 轉 ECharts 格式模版

```python
import pandas as pd
import json

def dataframe_to_echarts_dataset(df: pd.DataFrame) -> dict:
    """
    將分析聚合後的 DataFrame 自動轉為 ECharts 推薦的 dataset.source 格式
    可以直接嵌入 ECharts option 中
    """
    # 轉換時間欄位為字串
    for col in df.select_dtypes(include=['datetime64']).columns:
        df[col] = df[col].astype(str)
        
    # 生成 [columns, row1, row2, ...] 格式
    columns = list(df.columns)
    rows = df.values.tolist()
    source = [columns] + rows
    
    return {
        "dataset": {
            "source": source
        }
    }
```

## 多維度變數展示方案

### 1. 氣泡圖（適合3-4個維度）

**維度對映**：
- X軸：第一個變數
- Y軸：第二個變數
- 氣泡大小：第三個變數
- 氣泡顏色：第四個變數

**示例**：
```python
import plotly.express as px

df = px.data.iris()
fig = px.scatter(
    df,
    x="sepal_width",
    y="sepal_length",
    size="petal_length",      # 第四維：點大小
    color="species",           # 第五維：顏色區分
    hover_name="species"
)
fig.show()
```

**適用場景**：使用者/產品/業務的多維度對比分析

### 2. 熱力圖（適合展示矩陣關係）

**核心原理**：透過顏色深淺表達數值大小

**示例 - 指標與時間維度交叉**：
```python
import plotly.graph_objects as go
import pandas as pd
import numpy as np

data = np.random.rand(10, 12)  # 10個指標 x 12個月
labels_x = [f"2024-{str(i).zfill(2)}" for i in range(1, 13)]
labels_y = [f"指標{i}" for i in range(1, 11)]

fig = go.Figure(data=go.Heatmap(
    z=data,
    x=labels_x,
    y=labels_y,
    colorscale='RdYlGn',
    hovertemplate='指標: %{y}<br>時間: %{x}<br>值: %{z:.2f}<extra></extra>'
))
fig.show()
```

**適用場景**：指標波動監控、相關性分析、使用者行為矩陣

### 3. 雷達圖（適合對比多個維度）

**核心原理**：將多維度展開到同心圓軸線上

**示例 - 使用者畫像多維度對比**：
```python
import plotly.graph_objects as go

categories = ['活躍度', '購買力', '忠誠度', '傳播力', '滿意度', '復購率']

fig = go.Figure()

fig.add_trace(go.Scatterpolar(
    r=[85, 72, 90, 65, 88, 78],
    theta=categories,
    fill='toself',
    name='高價值使用者',
    line_color='red'
))

fig.add_trace(go.Scatterpolar(
    r=[45, 55, 60, 40, 65, 50],
    theta=categories,
    fill='toself',
    name='普通使用者',
    line_color='blue'
))

fig.update_layout(
    polar=dict(radialaxis=dict(visible=True, range=[0, 100])),
    showlegend=True,
    title="使用者畫像多維度對比"
)
fig.show()
```

**適用場景**：使用者分群、產品屬性對比、能力評估

### 4. 平行座標圖（適合5+維度）

**核心原理**：每個維度一條垂直軸，資料點用線連線

**示例**：
```python
import plotly.express as px

df = px.data.iris()
fig = px.parallel_coordinates(
    df,
    color="species",
    dimensions=['sepal_length', 'sepal_width', 'petal_length', 'petal_width'],
    color_continuous_scale=px.colors.diverging.Tealrose
)
fig.show()
```

**適用場景**：多指標監控、高維資料探索、聚類結果展示

### 5. 旭日圖（適合層級結構+佔比）

**核心原理**：環形圖的多層擴充套件

**示例 - 業務營收層級分解**：
```python
import plotly.express as px
import pandas as pd

df = pd.DataFrame({
    'labels': ['總營收', '產品A', '產品B', '產品A-區域1', '產品A-區域2', '產品B-區域1', '產品B-區域2'],
    'parents': ['', '總營收', '總營收', '產品A', '產品A', '產品B', '產品B'],
    'values': [100, 60, 40, 35, 25, 22, 18]
})

fig = px.sunburst(df, names='labels', parents='parents', values='values')
fig.show()
```

**適用場景**：營收分解、組織架構、業務結構分析

### 6. 桑基圖（適合流量/轉化分析）

**核心原理**：展示流量從源頭到終點的分配

**示例 - 使用者轉化路徑**：
```python
import plotly.graph_objects as go

fig = go.Figure(data=[go.Sankey(
    node=dict(
        pad=15,
        thickness=20,
        line=dict(color="black", width=0.5),
        label=["訪問", "註冊", "下單", "支付", "復購"],
        color=["blue", "green", "orange", "red", "purple"]
    ),
    link=dict(
        source=[0, 1, 2, 1, 3, 2],
        target=[1, 2, 3, 4, 4, 4],
        value=[1000, 400, 300, 100, 200, 150]
    )
)])
fig.show()
```

**適用場景**：轉化漏斗、流量分析、路徑追蹤

### 7. 分面圖（適合分組對比）

**核心原理**：將資料分組，在多個子圖中並排展示

**示例 - 按類別分組的時間序列**：
```python
import plotly.express as px

df = px.data.tips()
fig = px.line(
    df,
    x="size",
    y="total_bill",
    color="sex",
    facet_col="smoker",
    facet_row="time",
    title="各維度組合下的消費對比"
)
fig.show()
```

**適用場景**：多維度交叉分析、分組對比

### 8. 組合圖表（適合混合資料型別）

**核心原理**：在一個圖表區疊加多種圖表型別

**示例 - 趨勢+目標線+異常標記**：
```python
import plotly.graph_objects as go
import pandas as pd

dates = pd.date_range('2024-01-01', periods=30)
values = [100 + i*2 + (i%7)*5 + (i**1.1) + 50*((i%5)/5) for i in range(30)]

fig = go.Figure()

fig.add_trace(go.Scatter(
    x=dates,
    y=values,
    mode='lines+markers',
    name='實際值',
    line=dict(color='blue')
))

fig.add_trace(go.Scatter(
    x=dates,
    y=[120]*30,
    mode='lines',
    name='目標線',
    line=dict(color='green', dash='dash')
))

fig.add_trace(go.Scatter(
    x=dates[values.index(max(values))],
    y=[max(values)],
    mode='markers+text',
    marker=dict(color='red', size=15),
    text=['峰值'],
    name='異常點'
))

fig.update_layout(
    title="30天趨勢監控（多元素組合）",
    xaxis_title="日期",
    yaxis_title="數值"
)
fig.show()
```

**適用場景**：KPI監控、趨勢分析、異常檢測

## 進階視覺化技術

### 地理視覺化（基於位置的多維度）

**散點地圖 + 顏色/大小編碼**：
```python
import plotly.express as px

df = px.data.gapminder().query("year == 2007")

fig = px.scatter_geo(
    df,
    locations="iso_alpha",
    size="pop",
    color="lifeExp",
    hover_name="country",
    projection="natural earth",
    title="全球預期壽命分佈"
)
fig.show()
```

### 箱線圖 + 小提琴圖（分佈多維度）

**組合展示**：
```python
import plotly.express as px

df = px.data.tips()
fig = px.violin(
    df,
    y="total_bill",
    x="day",
    color="sex",
    box=True,
    points="all",
    hover_data=df.columns
)
fig.show()
```

### 3D散點圖（真正三維展示）

```python
import plotly.express as px

df = px.data.iris()
fig = px.scatter_3d(
    df,
    x='sepal_length',
    y='sepal_width',
    z='petal_length',
    color='species',
    size='petal_width',
    title="鳶尾花資料集 3D 視覺化"
)
fig.show()
```

## 配色與主題

### 配色原則
| 場景 | 推薦色板 | 說明 |
|------|----------|------|
| 數值遞增 | RdYlGn（紅-黃-綠） | 直觀表達大小 |
| 數值遞減 | YlOrRd（黃-橙-紅） | 警示類常用 |
| 分類對比 | 類別色板 | 區分不同類別 |
| 正負對比 | 藍色-紅色 | 正面-負面 |
| 統一主題 | 單色漸變 | 強調一致性 |

### 互動最佳實踐
```python
fig.update_layout(
    hovermode="x unified",      # 統一懸停
    hoverlabel=dict(
        bgcolor="white",
        font_size=12
    ),
    dragmode="pan"              # 拖拽平移
)
fig.show(config={"scrollZoom": True})
```

## 圖表選型速查表

| 分析目的 | 推薦圖表 |
|----------|----------|
| 趨勢分析 | 折線圖、面積圖 |
| 比較大小 | 柱狀圖、條形圖 |
| 佔比分佈 | 餅圖、環形圖、旭日圖 |
| 相關關係 | 散點圖、熱力圖 |
| 分佈形態 | 直方圖、箱線圖、小提琴圖 |
| 轉化路徑 | 桑基圖、漏斗圖 |
| 地理分佈 | 地圖、散點地圖 |
| 多維對比 | 雷達圖、平行座標、氣泡圖 |
| 分組對比 | 分面圖、組合圖 |

## 常見問題處理

### 維度過多怎麼辦？
1. **降維**：使用PCA或因子分析
2. **分面**：按某維度拆分多個子圖
3. **互動**：提供篩選器動態切換
4. **聚合**：高維轉低維聚合指標

### 資料量過大怎麼辦？
1. **取樣**：隨機抽樣或分箱
2. **聚合**：預聚合後展示
3. **漸進載入**：先概覽後細節
4. **資料視窗**：時間視窗切片

### 顏色使用誤區
1. 不使用紅綠色（色盲不友好）
2. 不使用過多顏色（≤7種）
3. 顏色要有語義一致性
4. 深淺表達數值大小

## 資源索引
- **ECharts 技能族**：`tool/echart`（折線、柱狀、關係、金融、統計、3D、多圖組合完整實現）
- Plotly 圖表庫：https://plotly.com/python/
- ECharts 官方示例庫：https://echarts.apache.org/examples/
- 顏色工具：https://colorbrewer2.org/

## 注意事項
- 視覺化是手段，不是目的，讓資料說話才是目的
- 多維度展示要考慮受眾的理解能力
- 互動要適度，避免過度複雜
- 靜態圖表優先考慮列印/分享場景
