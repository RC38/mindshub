---
name: dashboard-streamlit
version: v2.0.0
author: book-skills
description: Streamlit 數據展示技能，掌握文字、圖表、表格、互動元件的用法，實現豐富的數據視覺化介面
---
# Dashboard Streamlit

## 任務目標

- 本 Skill 用於：使用 Streamlit 元件建構數據展示介面
- 能力包含：文字顯示、數據表格、圖表渲染、表單輸入
- 觸發條件：需要在看板中展示數據或接收使用者輸入時

## 操作步驟

### 文字顯示

```python
import streamlit as st

st.title("頁面標題")
st.header("章節標題")
st.subheader("子標題")
st.markdown("**粗體** 和 *斜體* 文字")
st.caption("小字體說明文字")
st.code("print('Hello')", language="python")
st.text("等寬字體文字")
st.divider()
```

### 數據展示

```python
import streamlit as st
import pandas as pd

df = pd.DataFrame({
    'name': ['Alice', 'Bob', 'Charlie'],
    'score': [85, 92, 78]
})

# 互動式表格
st.dataframe(df, hide_index=True)

# 靜態表格
st.table(df)

# 編輯數據
edited_df = st.data_editor(df, num_rows="dynamic")
```

### 指標展示

```python
import streamlit as st

col1, col2, col3 = st.columns(3)

with col1:
    st.metric("總收入", "¥1,234,567", "+12.5%")

with col2:
    st.metric("使用者數", "8,888", "+5.2%")

with col3:
    st.metric("轉換率", "3.8%", "-0.3%")
```

### 圖表元件

```python
import streamlit as st
import pandas as pd
import numpy as np

df = pd.DataFrame(np.random.randn(20, 3), columns=['A', 'B', 'C'])

# 內建圖表
st.line_chart(df)
st.area_chart(df)
st.bar_chart(df)
st.scatter_chart(df)

# 地圖
st.map(df[['lat', 'lon']])
```

### PyDeck 圖表

```python
import streamlit as st
import pydeck as pdk

st.pydeck_chart(pdk.Deck(
    initial_view_state=pdk.ViewState(latitude=37.76, longitude=-122.4, zoom=11),
    layers=[pdk.Layer('ScatterplotLayer', data=df, get_position='[lon, lat]')]
))
```

### 表單與輸入

```python
import streamlit as st

with st.form(key='my_form'):
    name = st.text_input("姓名")
    choice = st.selectbox("選擇", ["A", "B", "C"])
    submitted = st.form_submit_button("送出")

if submitted:
    st.success(f"收到: {name}, {choice}")
```

### 側邊欄

```python
import streamlit as st

with st.sidebar:
    st.title("篩選")
    min_val = st.slider("最小值", 0, 100, 50)
    options = st.multiselect("類別", ["科技", "金融", "醫療"])

st.write(f"選擇了: {min_val}, {options}")
```

### 標籤頁與摺疊區塊

```python
import streamlit as st

tab1, tab2, tab3 = st.tabs(["銷售", "使用者", "庫存"])

with tab1:
    st.write("銷售數據")

with tab2:
    st.write("使用者數據")

with st.expander("查看詳情"):
    st.write("詳細數據...")
```

### 版面配置容器

```python
import streamlit as st

# 橫向版面配置
col1, col2 = st.columns([2, 1])
with col1:
    st.line_chart(data)
with col2:
    st.metric("當前值", value)

# 空容器（動態替換）
placeholder = st.empty()
placeholder.line_chart(data)

# 對話框
@st.dialog("確認")
def confirm():
    if st.button("確定"):
        st.session_state.confirmed = True
```

### 檔案上傳與下載

```python
import streamlit as st
import pandas as pd

uploaded_file = st.file_uploader("上傳 CSV", type=['csv'])

if uploaded_file:
    df = pd.read_csv(uploaded_file)
    st.dataframe(df)

# 下載
csv = df.to_csv(index=False)
st.download_button("下載 CSV", csv, "data.csv")
```

### 狀態與回饋

```python
import streamlit as st

# 載入狀態
with st.spinner("載入中..."):
    result = load_data()

st.success("載入完成!")

# Toast 提示
st.toast("操作成功", icon="✅")

# 進度條
progress = st.progress(0)
for i in range(100):
    progress.progress(i + 1)

# 氣球慶祝
st.balloons()
```

## 資源索引

- Streamlit API：https://docs.streamlit.io/develop/api-reference
- 文字元件：https://docs.streamlit.io/develop/api-reference/text
- 數據框架：https://docs.streamlit.io/develop/api-reference/data
- 圖表：https://docs.streamlit.io/develop/api-reference/charts
- 元件：https://docs.streamlit.io/develop/api-reference/components

## 注意事項

- st.dataframe 支援排序和篩選，適合大數據
- st.table 適合小數據靜態展示
- 表單使用 with st.form() 批次提交
- 側邊欄適合放置篩選器
