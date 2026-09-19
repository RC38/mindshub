---
name: analytics-statistics
display_name: Analytics Statistics（統計推斷與 A/B 實驗）
version: 1.0.0
description: Use when the user needs statistical inference, hypothesis testing, correlation analysis, or A/B test experimentation design and evaluation.
tags: [statistics, hypothesis-testing, ab-testing, correlation, p-value, sample-size]
---

# Analytics Statistics & A/B Testing

## 任務目標
- 本 Skill 用於：為數據分析師提供紮實的統計推斷、假設檢驗與 A/B 測試實戰指南。
- 能力包含：描述性統計與分佈探查、相關性分析、假設檢驗（t 檢驗、卡方檢驗）、A/B 測試全流程（樣本量估算、MDE、顯著性評估、實驗陷阱防範）。
- 觸發條件：需要驗證策略效果、對比兩組指標差異、計算統計顯著性、設計或分析 A/B 實驗時。

## 適用場景
- 新功能或營銷策略上線，需要判斷點擊率/轉化率/營收提升是否具備統計顯著性（非隨機波動）。
- 需要對變量進行關聯性檢驗，並排除虛假相關與辛普森悖論。
- 實驗上線前需要科學計算樣本量與實驗週期，避免樣本不足或流量浪費。

---

## 核心統計基礎與分佈檢驗

### 1. 描述性統計與分佈特徵
除了均值（Mean）與標準差（Std），偏度和峰度能幫助判斷數據是否偏離正態分佈：

```python
import numpy as np
import pandas as pd
from scipy import stats

def describe_distribution(series: pd.Series) -> dict:
    clean_series = series.dropna()
    mean_val = clean_series.mean()
    median_val = clean_series.median()
    std_val = clean_series.std()
    skew_val = clean_series.skew()     # > 0 右偏(長尾在右), < 0 左偏
    kurt_val = clean_series.kurtosis() # 峰度: > 0 比正態分佈更陡峭(厚尾)
    cv_val = std_val / mean_val if mean_val != 0 else np.nan # 變異係數
    
    # Shapiro-Wilk 正態性檢驗 (樣本數建議 <= 5000)
    shapiro_stat, shapiro_p = stats.shapiro(clean_series.sample(min(len(clean_series), 1000), random_state=42))

    return {
        "count": len(clean_series),
        "mean": round(mean_val, 4),
        "median": round(median_val, 4),
        "std": round(std_val, 4),
        "cv": round(cv_val, 4),
        "skewness": round(skew_val, 4),
        "kurtosis": round(kurt_val, 4),
        "is_normal": shapiro_p > 0.05
    }
```

### 2. 相關性分析（Correlation Analysis）
- **Pearson 相關係數**：衡量兩連續變量的**線性關係**，要求數據近似正態分佈。
- **Spearman 秩相關係數**：衡量兩變量的**單調關係**，適用於非正態分佈、等級順序變量或有長尾離群值的數據。

```python
import pandas as pd
from scipy import stats

def check_correlation(df: pd.DataFrame, col1: str, col2: str):
    data = df[[col1, col2]].dropna()
    pearson_r, pearson_p = stats.pearsonr(data[col1], data[col2])
    spearman_r, spearman_p = stats.spearmanr(data[col1], data[col2])
    
    print(f"Pearson r: {pearson_r:.4f} (p-value: {pearson_p:.4e})")
    print(f"Spearman r: {spearman_r:.4f} (p-value: {spearman_p:.4e})")
```

> [!WARNING]
> **相關非因果（Correlation ≠ Causation）**：高相關性可能來自共同潛在變量（Confounder）。同時務必警惕**辛普森悖論（Simpson's Paradox）**：在分組維度下均呈現負相關，匯總整體後卻呈現正相關，必須下鑽至細分人群驗證。

---

## 假設檢驗實戰（Hypothesis Testing）

假設檢驗遵循四步法：
1. 建立虛無假設 $H_0$（通常為「無差異」）與對立假設 $H_1$。
2. 設定顯著性水準 $\alpha$（通常為 $0.05$）。
3. 計算檢驗統計量與 $P$ 值（$P$-value）。
4. 若 $P < \alpha$，拒絕 $H_0$；否則無法拒絕 $H_0$。

### 1. 均值差異檢驗：獨立雙樣本 t 檢驗（Two-sample t-test）
適用於對比對照組（Control）與實驗組（Treatment）的連續指標（如人均客單價、停留時長）。

```python
from scipy import stats
import numpy as np

def compare_means(control: np.ndarray, treatment: np.ndarray, alpha=0.05):
    # 1. 檢查方差齊性 (Levene's Test)
    _, p_var = stats.levene(control, treatment)
    equal_var = p_var > 0.05
    
    # 2. 進行 t-test (若方差不齊則使用 Welch's t-test)
    t_stat, p_val = stats.ttest_ind(treatment, control, equal_var=equal_var)
    
    mean_ctrl, mean_treat = np.mean(control), np.mean(treatment)
    diff = mean_treat - mean_ctrl
    lift = (diff / mean_ctrl) * 100 if mean_ctrl != 0 else 0
    
    return {
        "mean_control": round(mean_ctrl, 4),
        "mean_treatment": round(mean_treat, 4),
        "absolute_diff": round(diff, 4),
        "lift_pct": f"{lift:+.2f}%",
        "equal_variance": equal_var,
        "p_value": round(p_val, 6),
        "significant": p_val < alpha
    }
```

### 2. 比率差異檢驗：雙比例 Z 檢驗 / 卡方檢驗（Chi-Square Test）
適用於比率指標（點擊率 CTR、付費轉化率 CVR、留存率）。

```python
from statsmodels.stats.proportion import proportions_ztest

def compare_proportions(count_ctrl, nobs_ctrl, count_treat, nobs_treat, alpha=0.05):
    """
    count_ctrl: 對照組轉化人數, nobs_ctrl: 對照組總曝光人數
    count_treat: 實驗組轉化人數, nobs_treat: 實驗組總曝光人數
    """
    counts = np.array([count_treat, count_ctrl])
    nobs = np.array([nobs_treat, nobs_ctrl])
    
    # 雙比例 z 檢驗
    z_stat, p_val = proportions_ztest(counts, nobs)
    
    rate_ctrl = count_ctrl / nobs_ctrl
    rate_treat = count_treat / nobs_treat
    lift = ((rate_treat - rate_ctrl) / rate_ctrl) * 100
    
    return {
        "rate_control": f"{rate_ctrl:.2%}",
        "rate_treatment": f"{rate_treat:.2%}",
        "lift_pct": f"{lift:+.2f}%",
        "z_statistic": round(z_stat, 4),
        "p_value": round(p_val, 6),
        "significant": p_val < alpha
    }
```

---

## A/B 測試（A/B Testing）全流程

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              A/B 測試科學實驗標準閉環                                  │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                        │
│  [1. 實驗設計] ──────→ [2. 流量分配] ──────→ [3. 運行監控] ──────→ [4. 結果決策]       │
│    • 業務假設確定        • 哈希分流分流        • AA 測試校準         • 顯著性檢定      │
│    • 核心/護欄指標       • 樣本量計算          • 嚴防偷窺 (Peeking)  • 置信區間評估    │
│    • MDE 設定            • 流量正交切分        • 異常波動熔斷        • 全量/回滾決策   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### 階段一：實驗前設計與樣本量估算
在實驗開始前，必須決定**需要多少樣本量**才能在統計上檢測出預期效果（避免「樣本太少看不出效果」或「樣本過多浪費流量」）。

#### 比率型指標樣本量計算公式代碼：
```python
from statsmodels.stats.power import NormalIndPower
import statsmodels.api as sm

def calculate_sample_size_proportion(baseline_rate: float, expected_lift: float, 
                                     alpha=0.05, power=0.8):
    """
    baseline_rate: 當前基準轉化率 (如 0.05 代表 5%)
    expected_lift: 預期相對提升幅度 (如 0.10 代表提升 10%，達到 5.5%)
    power: 統計功效 (通常設 0.8)
    """
    p1 = baseline_rate
    p2 = baseline_rate * (1 + expected_lift)
    
    # 計算效應量 (Cohen's h)
    effect_size = sm.stats.proportion_effectsize(p1, p2)
    
    power_analysis = NormalIndPower()
    sample_size_per_group = power_analysis.solve_power(
        effect_size=effect_size,
        power=power,
        alpha=alpha,
        ratio=1.0 # 兩組 1:1
    )
    
    return {
        "baseline_rate": f"{p1:.2%}",
        "target_rate": f"{p2:.2%}",
        "effect_size": round(effect_size, 4),
        "sample_size_per_group": int(np.ceil(sample_size_per_group)),
        "total_sample_required": int(np.ceil(sample_size_per_group * 2))
    }
```

### 階段二：指標體系分類
每次實驗必須明確定義三類指標：
1. **核心指標（Primary Metric）**：本次實驗旨在提升的核心目標（如結帳轉化率）。
2. **輔助指標（Secondary Metrics）**：幫助解釋核心指標變動原因的過程指標（如加購率、首頁點擊率）。
3. **護欄指標（Guardrail Metrics）**：確保實驗不會對大盤健康造成副作用的警戒指標（如頁面崩潰率、跳出率、投訴率、整體客單價）。

### 階段三：實驗運行中的關鍵避坑指南

> [!IMPORTANT]
> 1. **避免早停與偷窺效應（Peeking Problem）**：
>    每天看一次數據並在看到 $P < 0.05$ 時立即終止實驗，會使真實的第一類錯誤（偽陽性）膨脹到 20%~30% 以上！**嚴格規定達到預定樣本量與實驗週期（至少完整包含 1~2 個自然週以消除週期效應）前不輕易下結論**。
> 2. **AA 檢驗（AA Testing）**：
>    在正式實驗前或並行運行兩個無策略差異的組，驗證兩組指標在統計上無顯著差異，確保分流系統均勻。
> 3. **辛普森悖論檢驗**：
>    必須檢查各主要渠道（新/老用戶、iOS/Android、不同城市）的流量佔比在對照組和實驗組是否均衡，防止渠道結構偏移干擾整體結論。

---

## 決策速查表

| 指標類型 | 典型業務指標 | 推薦檢驗方法 | 關鍵輸出 |
|:---|:---|:---|:---|
| **比率指標 (0/1)** | 點擊率 (CTR)、轉化率 (CVR)、留存率 | 雙比例 Z 檢驗 / 卡方檢驗 | Lift %, P-value, 95% 置信區間 |
| **連續數值指標** | 客單價、人均瀏覽時長、人均步數 | 獨立樣本 t 檢驗 (Welch's t-test) | 均值差異, Lift %, P-value |
| **長尾偏態連續指標** | 人均 GMV (含大量 0 值與高客單) | Mann-Whitney U 檢驗 (非參數) 或 Bootstrap 抽樣 | 中位數對比, Bootstrap CI |
| **類別關聯性** | 不同年齡層偏好的商品品類 | 卡方獨立性檢驗 ($\chi^2$) | 卡方值, P-value, 關聯自由度 |

