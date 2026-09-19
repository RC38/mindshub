---
name: analytics-data-processing
display_name: Analytics Data Processing（數據清洗與特徵預處理）
version: 1.2.0
description: Use when the user needs data acquisition, comprehensive data cleaning, missing value imputation, outlier detection, data normalization, or feature preprocessing for analysis.
tags: [data-processing, data-cleaning, missing-values, outlier-detection, pandas, feature-engineering]
---

# Analytics Data Processing & Cleaning

## 任務目標
- 本 Skill 用於：掌握數據分析師在取數、數據清洗、缺失值處理、異常值檢測、特徵轉換與分析前置處理的完整實戰方法。
- 能力包含：多源數據獲取、缺失值診斷與高階插補、異常值檢測與處理（IQR/3-Sigma/Winsorization）、髒數據正規化、特徵分箱與偏態調整。
- 觸發條件：需要準備分析數據、清洗髒數據、處理缺失值與離群點、構建分析特徵矩陣時。

## 適用場景
- 原始數據存在大量缺失值、重複值、髒欄位或型態不一致。
- 數值分佈存在極端異常值（如金額為負、年齡 999 歲），需要科學甄別與平滑處理。
- 需要把連續數據分箱（如年齡分段、消費能力分層），或對偏態分佈做對數變換。

---

## 數據獲取與質量評估

### 1. 快速取數模版

```python
import pandas as pd
from sqlalchemy import create_engine

# 資料庫取數 (只取分析所需欄位，降低記憶體消耗)
engine = create_engine('postgresql+psycopg2://user:password@host:5432/dbname')
query = """
    SELECT user_id, order_id, order_date, amount, status
    FROM orders
    WHERE order_date >= '2024-01-01'
"""
df = pd.read_sql(query, engine)
```

### 2. 數據質量快速診斷（Data Profiling）

```python
def profile_dataset(df: pd.DataFrame) -> pd.DataFrame:
    """全面產出欄位類型、缺失率、唯一值數量、重複行與樣本分佈"""
    profile = []
    total_rows = len(df)
    
    for col in df.columns:
        null_count = df[col].isnull().sum()
        profile.append({
            "column": col,
            "dtype": str(df[col].dtype),
            "null_count": null_count,
            "null_rate_pct": round((null_count / total_rows) * 100, 2),
            "nunique": df[col].nunique(),
            "sample_value": df[col].dropna().iloc[0] if not df[col].dropna().empty else None
        })
        
    print(f"總記錄數: {total_rows} | 重複行數: {df.duplicated().sum()}")
    return pd.DataFrame(profile)
```

---

## 缺失值診斷與多策略填補（Missing Data Imputation）

缺失值不能盲目一律刪除或一律填 0，需依業務情境與缺失機制分類處理：

```
                              ┌────────────────────────┐
                              │     缺失值處理策略     │
                              └───────────┬────────────┘
                                          │
        ┌─────────────────────────────────┼─────────────────────────────────┐
        ▼                                 ▼                                 ▼
   [直接刪除]                        [統計值填補]                      [進階模型/插值]
  缺失率極高(>70%)               數值型: 中位數/均值               時序: 線性插值/ffill
  或核心主鍵(user_id)缺失        類別型: 眾數/標記'Unknown'         多變量: KNN / 回歸預測
```

### 1. 統計值與分組填補
```python
import pandas as pd
import numpy as np

# 1. 數值型：正態分佈用均值，偏態分佈強烈推薦用「中位數」
df['amount_filled'] = df['amount'].fillna(df['amount'].median())

# 2. 類別型：用眾數或單獨填補為新分類
df['city_filled'] = df['city'].fillna(df['city'].mode()[0] if not df['city'].mode().empty else 'Unknown')

# 3. 細分組填補（推薦：同品類/同等級用戶的分組中位數）
df['salary_filled'] = df.groupby('job_title')['salary'].transform(lambda x: x.fillna(x.median()))

# 4. 建立「缺失指示變量」（保留缺失本身作為特徵信號）
df['amount_was_missing'] = df['amount'].isnull().astype(int)
```

### 2. 時間序列插補
```python
# 適用於連續變量時序監控（如每日活躍數、日溫度）
df['metric_ffill'] = df['metric'].ffill()                 # 前向填補
df['metric_linear'] = df['metric'].interpolate(method='linear') # 線性插值
```

### 3. 高階多變量 KNN 填補
```python
from sklearn.impute import KNNImputer

def knn_impute(df: pd.DataFrame, feature_cols: list, n_neighbors=5) -> pd.DataFrame:
    """利用相似樣本的加權特徵填充缺失值"""
    imputer = KNNImputer(n_neighbors=n_neighbors)
    df_imputed = df.copy()
    df_imputed[feature_cols] = imputer.fit_transform(df[feature_cols])
    return df_imputed
```

---

## 異常值檢測與處理（Outlier Detection）

異常值包括：**業務真異常**（如測試帳號刷單）與**極端極值**（如超高淨值 VIP）。

### 1. IQR 箱線圖法（非正態分佈首選）
```python
import pandas as pd

def detect_outliers_iqr(series: pd.Series, factor=1.5):
    """
    factor=1.5 為標準異常值，factor=3.0 為極端異常值
    """
    Q1 = series.quantile(0.25)
    Q3 = series.quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = Q1 - factor * IQR
    upper_bound = Q3 + factor * IQR
    
    outlier_mask = (series < lower_bound) | (series > upper_bound)
    return outlier_mask, lower_bound, upper_bound
```

### 2. 3-Sigma 原則（近似正態分佈）
```python
def detect_outliers_zscore(series: pd.Series, threshold=3.0):
    mean = series.mean()
    std = series.std()
    z_scores = (series - mean) / std
    outlier_mask = z_scores.abs() > threshold
    return outlier_mask, mean - threshold * std, mean + threshold * std
```

### 3. 異常值處理三大策略
```python
# 策略一：分位數截斷蓋帽（Winsorization）—— 保留樣本，限制極端權重
lower_cap = df['amount'].quantile(0.01)
upper_cap = df['amount'].quantile(0.99)
df['amount_capped'] = df['amount'].clip(lower=lower_cap, upper=upper_cap)

# 策略二：將異常值轉換為 NaN，再使用中位數填補
mask, _, _ = detect_outliers_iqr(df['amount'])
df.loc[mask, 'amount_clean'] = np.nan
df['amount_clean'] = df['amount_clean'].fillna(df['amount_clean'].median())

# 策略三：業務過濾（直接排除非合理值，如年齡 <= 0 或 > 120）
df_filtered = df[(df['age'] > 0) & (df['age'] <= 120)]
```

---

## 髒數據清洗與格式正規化

### 1. 字串清洗與正規化
```python
# 去除前後多餘空白與全半角空格
df['user_name'] = df['user_name'].astype(str).str.strip()

# 手機號/證件正則提取與脫敏
df['clean_phone'] = df['phone'].str.replace(r'\D', '', regex=True) # 只留數字
df['masked_phone'] = df['clean_phone'].apply(lambda x: x[:3] + '****' + x[7:] if len(str(x)) == 11 else x)

# 類別名稱對齊 (如 'iOS', 'ios', 'Apple' 統一為 'iOS')
mapping = {'ios': 'iOS', 'apple': 'iOS', 'android': 'Android'}
df['os_type'] = df['os_type'].str.lower().map(mapping).fillna('Other')
```

### 2. 日期時間解析與標準化
```python
# 容錯解析各類日期字串
df['order_date'] = pd.to_datetime(df['order_date'], errors='coerce')

# 提取分析常用時間維度
df['order_year'] = df['order_date'].dt.year
df['order_month'] = df['order_date'].dt.to_period('M')
df['day_of_week'] = df['order_date'].dt.day_name()
df['is_weekend'] = df['order_date'].dt.dayofweek.isin([5, 6]).astype(int)
df['hour'] = df['order_date'].dt.hour
```

---

## 特徵工程與分析前轉換

### 1. 數值特徵分箱（Binning）
將連續變量轉換為有意義的離散業務維度：

```python
# 等寬分箱 (依數值區間)
df['age_group'] = pd.cut(
    df['age'], 
    bins=[0, 18, 25, 35, 50, 100], 
    labels=['<18', '18-25', '26-35', '36-50', '50+']
)

# 等頻分箱 (依百分位人數均分，例如劃分高/中/低消費人群)
df['spend_level'] = pd.qcut(
    df['total_spend'].rank(method='first'), 
    q=3, 
    labels=['低消費', '中消費', '高消費']
)
```

### 2. 偏態分佈平滑轉換
在營收、點擊量等長尾分佈中，極端值會拉高整體方差，可進行對數變換：

```python
# log1p 避免 0 值報錯 (log(1 + x))
df['log_amount'] = np.log1p(df['amount'].clip(lower=0))
```

### 3. 類別特徵編碼（Encoding）
```python
# One-Hot 編碼 (適用於無次序分類，如付款方式)
df = pd.get_dummies(df, columns=['payment_method'], prefix='pay', drop_first=True)

# 順序編碼 (適用於有次序類別，如會員等級)
level_map = {'Bronze': 1, 'Silver': 2, 'Gold': 3, 'Platinum': 4}
df['member_level_code'] = df['member_level'].map(level_map)
```

---

## 數據清洗檢核清單（Checklist）

在展開進一步的統計分析、可視化或報告前，請確認：
- [ ] **唯一性**：主鍵（如 `order_id`）是否已完成去重，確認無重複行？
- [ ] **缺失率**：各欄位缺失情況是否已診斷？關鍵欄位是否已完成合理填補？
- [ ] **邊界合理性**：數值型欄位是否在業務允許範圍內（無負數時長、未來日期）？
- [ ] **型別正確性**：日期是否已轉為 `datetime`？數值是否已轉為 `int/float`？
- [ ] **口徑統一性**：枚舉分類是否已對齊（大小寫、同義詞合併）？
- [ ] **原始備份**：清洗操作是否都在新建欄位中進行，保留了可追溯的原值？
