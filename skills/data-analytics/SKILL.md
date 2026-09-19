---
name: data-analytics
display_name: Data Analytics Skills（數據分析師技能庫）
version: 2.0.0
description: Use when the user needs a comprehensive data analyst skill entry point, sub-skill routing, or guidance across the full analytics lifecycle from cleaning to reporting.
tags: [analytics, data-analysis, data-cleaning, statistics, ab-testing, business-models, visualization, reporting]
---

# Data Analytics Skills（數據分析師技能庫）

## 任務目標
- 作為**數據分析師（Data Analyst）全能力體系**的統一入口與導航地圖。
- 覆蓋數據分析完整生命週期：從數據獲取清洗、統計推斷、A/B 測試、業務模型到視覺化與報告交付。
- 觸發條件：使用者提到數據分析、數據清洗、補缺值、異常值剔除、統計檢驗、A/B 測試、同期群留存、RFM 分群、業務異動歸因、圖表展示或分析報告撰寫。

---

## 數據分析師技能地圖

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              數據分析師技能全景地圖                                     │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                        │
│  [1. 核心流程與目標] ➔ analytics-core                                                  │
│     • 七階段分析流程 / 分析目標設定 / 商業價值實現 / 定性與定量思考                      │
│                                                                                        │
│  [2. 數據清洗與預處理] ➔ analytics-data-processing                                      │
│     • 缺失值診斷與多策略填補 / 異常值檢測 (IQR & 3σ) / 髒數據正規化 / 特徵分箱轉換      │
│                                                                                        │
│  [3. 統計推斷與實驗] ➔ analytics-statistics                                            │
│     • 描述性統計與分佈檢驗 / 假設檢驗 (t-test, 卡方) / A/B 測試 (樣本量計算, MDE, 避坑) │
│                                                                                        │
│  [4. 業務模型與歸因] ➔ analytics-business-methods                                      │
│     • 指標體系 (OSM/北極星) / 漏斗轉化 / 同期群留存 (Cohort) / RFM / 異動歸因 (RCA)   │
│                                                                                        │
│  [5. 多維視覺化呈現] ➔ analytics-visualization                                          │
│     • 圖表選型決策樹 / 多維度變量展示 (氣泡/熱力/雷達/桑基) / Plotly 互動式看板設計    │
│                                                                                        │
│  [6. 結構化分析報告] ➔ analytics-report                                                 │
│     • 結論前置七段式報告 / 決策層與執行層讀者分層 / 診斷與監控模板 / 交付規範          │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 子技能清單與導航

| 階段 | 子技能目錄 | 核心能力 | 推薦適用場景 |
|:---|:---|:---|:---|
| **① 流程方法** | [analytics-core](analytics-core/) | 分析全鏈路框架、問題拆解、目標量化、價值發現 | 專案啟動、需求梳理、不知從何下手時 |
| **② 清洗處理** | [analytics-data-processing](analytics-data-processing/) | 補缺失值、異常值剔除、數據轉換、特徵分箱、資料質量評估 | 取數後髒數據處理、欄位缺失、極端值修正 |
| **③ 統計實驗** | [analytics-statistics](analytics-statistics/) | 描述統計、假設檢驗（t檢驗/卡方）、A/B Test 實驗設計、樣本量估算 | 評估策略顯著性、檢驗兩組差異、實驗避坑 |
| **④ 業務分析** | [analytics-business-methods](analytics-business-methods/) | 指標體系（OSM/北極星）、漏斗分析、留存 Cohort、RFM 客戶分群、異動歸因 | 用戶運營、活動復盤、大盤暴跌/暴漲根因排查 |
| **⑤ 數據視覺** | [analytics-visualization](analytics-visualization/) | 多維圖表選型、維度映射、儀表盤設計（Web/大屏可聯動調用 `tool/echart`） | 結果展示、管理層看板、高維數據探索、ECharts 圖表實現 |
| **⑥ 報告交付** | [analytics-report](analytics-report/) | 七段式標準結構、結論前置、受眾分層策略、模板化輸出 | 向管理層/業務方匯報、撰寫專題分析報告 |

---

## 快速選型速查表

| 使用者問題 / 需求描述 | 優先推薦子技能 |
|:---|:---|
| 「不知道這個分析專案該怎麼開始拆解？」 | `analytics-core` |
| 「數據裡有很多空值，該填中位數還是均值？」 | `analytics-data-processing` |
| 「數值有極端異常值（如年齡 999），怎麼用 IQR 剔除或截斷？」 | `analytics-data-processing` |
| 「想做特徵分箱，把用戶劃分為高/中/低消費人群」 | `analytics-data-processing` |
| 「A 組點擊率 3.5%，B 組 4.1%，這是否具備統計顯著性？」 | `analytics-statistics` |
| 「準備做一個 A/B 測試，需要多少樣本量和實驗天數？」 | `analytics-statistics` |
| 「這週 GMV 突然跌了 15%，幫我排查是哪裡出了問題」 | `analytics-business-methods` |
| 「想看新用戶的 30 天次月留存率熱力圖矩陣」 | `analytics-business-methods` |
| 「運營需要針對用戶做精準營銷，如何進行 RFM 客戶分群？」 | `analytics-business-methods` |
| 「有多個指標要同時對比，該選雷達圖、散點圖還是熱力圖？」 | `analytics-visualization` |
| 「需要寫一份給 CEO 匯報的業務診斷報告，該怎麼組織？」 | `analytics-report` |

---

## 組合任務協同路徑

1. **新業務上線效果評估**：
   `analytics-core`（定義核心目標與假設） ➔ `analytics-data-processing`（清洗實驗日誌數據） ➔ `analytics-statistics`（A/B 測試顯著性檢定與 P-value） ➔ `analytics-report`（輸出上線成效決策報告）
2. **大盤異常排查與復盤**：
   `analytics-business-methods`（加法/乘法拆解與維度貢獻度） ➔ `analytics-visualization`（趨勢與漏斗可視化呈現） ➔ `analytics-report`（產出異動診斷報告）
3. **用戶全生命週期畫像**：
   `analytics-data-processing`（特徵分箱與變量編碼） ➔ `analytics-business-methods`（Cohort 留存矩陣 + RFM 分群） ➔ `analytics-visualization`（熱力圖與桑基圖）
