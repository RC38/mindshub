---
name: dashboard-pandas
version: v2.5.0
author: book-skills
description: Pandas 數據前處理與 ECharts 導出技能，掌握從原始數據讀取、清洗、聚合，到導出為靜態 HTML / ECharts 所需的 JSON 與 JS 數據結構
---

# Dashboard Pandas (Data Preparation for Static HTML)

## 任務目標
- 本 Skill 用於：在**開發/分析階段**使用 Python Pandas 對數據進行讀取、清洗、聚合，並導出為供靜態 HTML 看板與 Apache ECharts 直接使用的數據格式。
- 能力包含：數據清洗與型別轉換、統計聚合、多維度交叉分析、導出為 ECharts 專用結構（類別軸陣列、數值陣列、JSON 對象、內嵌 JS 變數）。
- **重要聲明**：Pandas 僅作為**開發者端**離線數據處理工具；**最終產出的靜態 HTML 交付給客戶時，客戶端完全免安裝 Python、pip 或 Streamlit**。

---

## 導出為 Apache ECharts 標準格式

Apache ECharts 最常使用的數據結構有三種，Pandas 可一鍵快速轉換：

### 1. 導出為分離的 X 軸與系列陣列 (Category + Series Array)
最常用於折線圖與柱狀圖：

```python
import pandas as pd
import json

df = pd.read_csv('sales.csv')

# 聚合每日銷售額
daily_sales = df.groupby('date')['revenue'].sum().reset_index()

# 提取 X 軸標籤與 Y 軸數值清單
categories = daily_sales['date'].astype(str).tolist()
revenues = daily_sales['revenue'].round(2).tolist()

print("xAxis categories:", json.dumps(categories, ensure_ascii=False))
print("series data:", json.dumps(revenues))
```

產生的數據可直接貼入或動態載入至 ECharts：
```javascript
const option = {
  xAxis: { type: 'category', data: ["2024-05-01", "2024-05-02", "2024-05-03"] },
  series: [{ type: 'line', data: [12000, 15300, 18200] }]
};
```

---

### 2. 導出為圓餅圖專用的 Name-Value 鍵值陣列
適用於圓餅圖、環形圖、南丁格爾玫瑰圖：

```python
# 聚合品類佔比
category_sales = df.groupby('category')['revenue'].sum().reset_index()
category_sales.columns = ['name', 'value']

# 導出為 List of Dicts
pie_data = category_sales.to_dict(orient='records')
print(json.dumps(pie_data, ensure_ascii=False, indent=2))
```

輸出範例：
```json
[
  { "name": "3C 數位家電", "value": 450000 },
  { "name": "流行服飾", "value": 280000 },
  { "name": "生鮮食品", "value": 150000 }
]
```

在 HTML ECharts 中直接使用：
```javascript
series: [{
  type: 'pie',
  data: pie_data
}]
```

---

### 3. 多系列分組導出 (Grouped / Stacked Charts)
適用於對比不同地區、不同品類的走勢：

```python
# 樞紐分析 (Pivot Table)
pivot_df = df.pivot_table(index='date', columns='region', values='revenue', aggfunc='sum', fill_value=0)

dates = pivot_df.index.astype(str).tolist()
series_list = []

for region in pivot_df.columns:
    series_list.append({
        "name": region,
        "type": "bar",
        "data": pivot_df[region].round(2).tolist()
    })

echarts_config = {
    "dates": dates,
    "series": series_list
}

with open("chart_data.json", "w", encoding="utf-8") as f:
    json.dump(echarts_config, f, ensure_ascii=False, indent=2)
```

---

### 4. 直接產生嵌入式 JavaScript 檔案 (data.js)
若不想使用 Ajax/fetch（避免本機直接雙擊 HTML 出現 CORS 限制），可由 Python 直接產生 `data.js`：

```python
import json

dashboard_data = {
    "kpi": {
        "total_revenue": "NT$ 2,458,900",
        "total_orders": 1280,
        "active_users": 45600
    },
    "trend": {
        "dates": ["05-14", "05-15", "05-16", "05-17", "05-18", "05-19", "05-20"],
        "revenue": [3200, 4100, 3900, 5200, 6100, 7500, 8900]
    },
    "recent_orders": df.head(10).to_dict(orient='records')
}

# 寫出為 JS 變數定義
with open("data.js", "w", encoding="utf-8") as f:
    f.write(f"const DASHBOARD_DATA = {json.dumps(dashboard_data, ensure_ascii=False, indent=2)};\n")
```

HTML 中只需引入：
```html
<script src="data.js"></script>
<script>
  console.log(DASHBOARD_DATA.kpi.total_revenue);
</script>
```
這能讓客戶**在無任何伺服器環境下，直接雙擊 `index.html`** 也能順暢讀取數據！

---

## 常用數據清洗模式

```python
import pandas as pd

# 讀取 CSV
df = pd.read_csv('raw_data.csv')

# 1. 處理缺失值
df['revenue'] = df['revenue'].fillna(0)
df['customer_name'] = df['customer_name'].fillna('未知客戶')

# 2. 日期格式標準化
df['order_date'] = pd.to_datetime(df['order_date']).dt.strftime('%Y-%m-%d')

# 3. 數值型別轉換與異常值過濾
df['price'] = pd.to_numeric(df['price'], errors='coerce').fillna(0)
df = df[df['price'] >= 0]

# 4. 新增衍生指標 (如客單價、折扣後金額)
df['total_amount'] = (df['price'] * df['quantity'] * (1 - df['discount'])).round(2)
```

---

## 注意事項

1. **零安裝交付**：Python 與 Pandas 僅在數據分析師本機運行；發給客戶時只需發送生成的 `.html`、`.js`、`.css`，客戶免安裝任何 Python 環境。
2. **避免 CORS 限制**：在部分瀏覽器（如 Chrome）中，本機以 `file:///` 協議打開 HTML 時，`fetch('data.json')` 可能受限。推薦將數據輸出為 `data.js` 宣告全局變數，或直接內嵌於 HTML 中。
