---
name: analytics-business-methods
display_name: Analytics Business Methods（業務模型與異動歸因）
version: 1.0.0
description: Use when the user needs business analysis models, cohort retention, funnel analysis, RFM customer segmentation, metrics tree definition, or root cause anomaly attribution.
tags: [business-analysis, cohort, funnel, rfm, metrics-framework, root-cause-analysis, anomaly-attribution]
---

# Analytics Business Methods & Metric Diagnosis

## 任務目標
- 本 Skill 用於：掌握數據分析師在真實商業世界中最常用的業務分析模型與指標異動歸因方法論。
- 能力包含：商業指標體系構建（OSM 模型、北極星指標）、四大業務模型（漏斗分析、同期群留存、RFM 用戶分群、LTV/CAC）、指標異動診斷（Root Cause Analysis）。
- 觸發條件：需要搭建指標監控體系、進行用戶行為分析、拆解業務大盤暴跌/暴漲原因時。

## 適用場景
- 業務指標出現異常波動（如 GMV 下滑 15%），需要快速定位根因。
- 評估用戶黏性與流失節奏，需要產出同期群（Cohort）留存矩陣。
- 運營需要精準營銷，需要根據用戶消費習慣進行 RFM 畫像分層。
- 梳理新產品或業務線的指標體系，定義核心度量。

---

## 商業指標體系構建方法

### 1. OSM 模型（Objective - Strategy - Measure）
搭建指標體系的黃金標準架構：
- **Objective（目標）**：業務存在的初衷，為用戶創造什麼價值？（如：讓用戶更高效獲取優質商品）
- **Strategy（策略）**：為了達成目標採取的業務手段（如：個性化推薦、促銷補貼、新客歡迎禮）
- **Measure（度量）**：衡量策略成效的具體指標，分為：
  - **感性指標（用戶心智）**：滿意度 NPS、投訴率
  - **行為指標（用戶行為）**：活躍天數、加購率、瀏覽時長
  - **商業指標（財務結果）**：GMV、客單價、ROI

### 2. 指標分級標準
- **L1 指標（北極星 / CEO 看板）**：公司的核心經營目標（如 GMV、年度活躍買家數 AAC）。
- **L2 指標（業務線負責人看板）**：支撐 L1 指標的業務模組指標（如 新客獲客成本 CAC、品類轉化率、30 天復購率）。
- **L3 指標（執行層運營指標）**：細分流程與頁面功能指標（如 搜尋無結果率、結帳按鈕點擊率、優惠券核銷率）。

---

## 四大經典業務模型實戰

### 1. 漏斗轉化分析（Funnel Analysis）
追蹤用戶在特定流程中每一環節的留存與流失：

```python
import pandas as pd

def calculate_funnel(df: pd.DataFrame, step_cols: list) -> pd.DataFrame:
    """
    step_cols: 各階段用戶數或事件數，例如 ['瀏覽商品', '加入購物車', '提交訂單', '完成支付']
    """
    funnel_data = []
    initial_count = df[step_cols[0]].nunique()
    
    for i, step in enumerate(step_cols):
        current_count = df[step].nunique()
        prev_count = df[step_cols[i-1]].nunique() if i > 0 else current_count
        
        step_conversion = (current_count / prev_count) * 100 if prev_count > 0 else 0
        overall_conversion = (current_count / initial_count) * 100 if initial_count > 0 else 0
        dropoff_rate = 100 - step_conversion if i > 0 else 0
        
        funnel_data.append({
            "步驟": step,
            "用戶數": current_count,
            "環節轉化率(%)": round(step_conversion, 2),
            "總體轉化率(%)": round(overall_conversion, 2),
            "流失率(%)": round(dropoff_rate, 2)
        })
        
    return pd.DataFrame(funnel_data)
```

### 2. 同期群留存分析（Cohort Analysis）
按用戶首次活躍/首購月份劃分，追蹤後續月份的留存表現：

```python
import pandas as pd
import numpy as np

def generate_cohort_matrix(df: pd.DataFrame, user_id_col='user_id', date_col='order_date') -> pd.DataFrame:
    """
    輸出以首購月為 CohortGroup，後續月數為週期 (Period 0, 1, 2...) 的留存率矩陣
    """
    df = df.copy()
    df['order_period'] = df[date_col].dt.to_period('M')
    
    # 標記每個用戶的首購期
    df['cohort_group'] = df.groupby(user_id_col)['order_period'].transform('min')
    
    # 計算相對月數
    df['period_number'] = (df['order_period'].dt.year - df['cohort_group'].dt.year) * 12 + \
                          (df['order_period'].dt.month - df['cohort_group'].dt.month)
    
    # 統計每個同期群在各週期的獨立用戶數
    cohort_counts = df.groupby(['cohort_group', 'period_number'])[user_id_col].nunique().reset_index()
    cohort_pivot = cohort_counts.pivot(index='cohort_group', columns='period_number', values=user_id_col)
    
    # 計算留存率 (除以 Period 0 的初始人數)
    cohort_size = cohort_pivot.iloc[:, 0]
    retention_matrix = cohort_pivot.divide(cohort_size, axis=0) * 100
    
    return retention_matrix.round(2)
```

### 3. RFM 客戶價值模型
基於 **Recency（最近消費距離天數）**、**Frequency（消費頻次）**、**Monetary（消費總金額）** 進行用戶分群：

```python
import pandas as pd

def calculate_rfm_segments(df: pd.DataFrame, user_col='user_id', date_col='order_date', amount_col='amount', reference_date=None) -> pd.DataFrame:
    if reference_date is None:
        reference_date = df[date_col].max() + pd.Timedelta(days=1)
        
    rfm = df.groupby(user_col).agg({
        date_col: lambda x: (reference_date - x.max()).days, # Recency
        user_col: 'count',                                   # Frequency
        amount_col: 'sum'                                    # Monetary
    }).rename(columns={date_col: 'R', user_col: 'F', amount_col: 'M'})
    
    # 分位數評分 (1~5分，R 越小越好所以倒序)
    rfm['R_score'] = pd.qcut(rfm['R'], 5, labels=[5, 4, 3, 2, 1])
    rfm['F_score'] = pd.qcut(rfm['F'].rank(method='first'), 5, labels=[1, 2, 3, 4, 5])
    rfm['M_score'] = pd.qcut(rfm['M'].rank(method='first'), 5, labels=[1, 2, 3, 4, 5])
    
    # 與平均分對比，高於平均記為 1，低於記為 0
    for col in ['R_score', 'F_score', 'M_score']:
        rfm[col] = rfm[col].astype(int)
        
    rfm['R_high'] = rfm['R_score'] >= rfm['R_score'].mean()
    rfm['F_high'] = rfm['F_score'] >= rfm['F_score'].mean()
    rfm['M_high'] = rfm['M_score'] >= rfm['M_score'].mean()
    
    # 劃分 8 大用戶群
    def segment_user(row):
        if row['R_high'] and row['F_high'] and row['M_high']:
            return "重要價值客戶 (VIP)"
        elif not row['R_high'] and row['F_high'] and row['M_high']:
            return "重要喚回客戶 (即將流失高價值)"
        elif row['R_high'] and not row['F_high'] and row['M_high']:
            return "重要發展客戶 (高潛力高客單)"
        elif not row['R_high'] and not row['F_high'] and row['M_high']:
            return "重要挽留客戶 (曾高消費已沈睡)"
        elif row['R_high'] and row['F_high'] and not row['M_high']:
            return "一般高頻客戶 (低單價高活躍)"
        elif row['R_high'] and not row['F_high'] and not row['M_high']:
            return "新用戶 / 一般發展客戶"
        elif not row['R_high'] and row['F_high'] and not row['M_high']:
            return "一般保持客戶"
        else:
            return "低價值流失客戶"
            
    rfm['Segment'] = rfm.apply(segment_user, axis=1)
    return rfm
```

---

## 指標異常波動診斷（Root Cause Analysis, RCA）

當業務核心指標出現大幅波動時（如營收同比下降 15%），遵循「**確定波動 ➔ 公式拆解 ➔ 維度下鑽 ➔ 驗證假設**」四步法。

### 1. 拆解邏輯體系

```
                           ┌───────────────────────────┐
                           │      核心指標異動 (GMV)    │
                           └─────────────┬─────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
         [乘法拆解 (業務公式)]                            [加法拆解 (結構維度)]
    GMV = 訪客數(UV) × 轉化率 × 客單價                GMV = 渠道A + 渠道B + 渠道C
                 │                                               │
                 ▼                                               ▼
        哪個因子下降最劇烈？                              哪個結構貢獻了主要跌幅？
```

### 2. 異動貢獻度定量計算
當總指標 $Y = \sum X_i$ 發生變化時，各維度分支 $i$ 的**貢獻率**公式為：

$$\text{貢獻率}_i = \frac{X_{i,\text{本期}} - X_{i,\text{基準期}}}{Y_{\text{本期}} - Y_{\text{基準期}}} \times 100\%$$

```python
import pandas as pd

def calculate_dimension_contribution(df_base: pd.DataFrame, df_current: pd.DataFrame, 
                                     dim_col: str, metric_col: str) -> pd.DataFrame:
    """
    計算某個分類維度對總體指標變動的貢獻度
    """
    s_base = df_base.groupby(dim_col)[metric_col].sum()
    s_curr = df_current.groupby(dim_col)[metric_col].sum()
    
    merged = pd.concat([s_base, s_curr], axis=1, keys=['base', 'current']).fillna(0)
    merged['diff'] = merged['current'] - merged['base']
    
    total_diff = merged['diff'].sum()
    merged['contribution_rate_pct'] = (merged['diff'] / total_diff) * 100 if total_diff != 0 else 0
    
    return merged.sort_values(by='diff', ascending=True).round(2)
```

### 3. 排查清單檢核表

- [ ] **是否為假性異常**：數據統計口徑是否變更？ETL 抽取出錯或延遲？日曆效應（工作日 vs 週末、春節效應）？
- [ ] **外部客觀因素**：政策監管、行業淡旺季、競品大規模營銷/補貼、極端天氣？
- [ ] **內部主觀因素**：版本迭代 Bug、伺服器當機/網絡故障、優惠券發放異常、推薦算法模型重訓？

