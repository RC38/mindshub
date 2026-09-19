---
name: parquet
display_name: Apache Parquet
version: 1.0.0
description: Python 處理 Apache Parquet 檔案技能 — 包含依賴管理（uv / pip）、Schema 與欄位元數據無開銷檢視、下推過濾高效查詢、SQL 直接查詢（DuckDB）、寫入與壓縮最佳化，以及 CSV / Excel 批次高效轉存 Parquet。
tags: [parquet, apache-parquet, python, pyarrow, duckdb, uv, dataframe, data-processing, excel, csv]
---

# Python 處理 Apache Parquet 檔案技能

## 角色設定

你是 **Parquet 與大數據檔案處理專家**，專注於指導如何使用現代 Python 工具鏈高效、低記憶體消耗地處理 Apache Parquet 檔案。

### 核心原則

- **零記憶體浪費**：優先利用 Parquet 列式儲存（Columnar）特性，絕不輕易 `read_table()` 或全載入記憶體。
- **現代工具鏈優先**：推薦使用 `uv` 進行套件管理與腳本執行，使用 `DuckDB` 進行互動式 SQL 探索，使用 `PyArrow` 進行底層精確控制。
- **下推過濾（Predicate Pushdown）**：查詢時永遠將過濾條件與欄位投影下推至磁碟層級。

---

## 觸發場景

- 「用 Python 讀取 Parquet 檔案」
- 「查看 Parquet 檔案有哪些欄位與資料型態」
- 「在不載入全部 Parquet 資料的情況下查詢某一筆資料」
- 「Parquet 套件依賴要怎麼安裝（uv / pip）」
- 「如何將 DataFrame 或資料寫入 Parquet 並設定壓縮」
- 「把 Excel (.xlsx) 批次轉存成 Parquet」
- 「單一 CSV 檔案過大，要批次（分片）轉存成 Parquet」
- 「大 Parquet 資料集要分頁瀏覽 / 依條件查詢顯示」

---

## 1. 依賴安裝與環境配置

推薦優先使用 **`uv`**（速度快 10~100 倍，且能自動處理複雜的 C++/二進位依賴）。

### 情境 A：使用 uv 專案模式（有 `pyproject.toml`）
```bash
# 核心官方套件 PyArrow + 嵌入式極速 SQL 引擎 DuckDB
uv add pyarrow duckdb

# 若需要搭配 Pandas、Polars 或處理 Excel
uv add pandas polars openpyxl
```

### 情境 B：使用 uv 虛擬環境（快速替代 pip）
```bash
uv pip install pyarrow duckdb pandas openpyxl
```

### 情境 C：獨立腳本 PEP 723 零配置執行（最推薦）
隨附的所有工具腳本皆已內嵌 PEP 723 宣告，無需手動建立虛擬環境即可直接以 `uv run` 執行：
```bash
uv run scripts/list_parquet_columns.py "data.parquet"
uv run scripts/query_parquet.py "data.parquet" -w "id = 100"
uv run scripts/csv_to_parquet.py "log.csv"
uv run scripts/xlsx_to_parquet.py "data.xlsx"
```

### 情境 D：傳統 pip 安裝（受限環境）
```bash
pip install pyarrow duckdb pandas openpyxl
```

---

## 2. 核心操作配方（Cookbook）

### 配方 1：僅讀取 Schema 與欄位清單（零資料加載，毫秒級響應）

Parquet 檔案尾部包含 Metadata，使用 `pyarrow.parquet.read_schema` 或 `ParquetFile` 僅讀取 Metadata，完全不會把任何資料載入記憶體：

#### 方法 A：使用 PyArrow
```python
import pyarrow.parquet as pq

file_path = "data.parquet"

# 方式 1：直接讀取 Schema 物件
schema = pq.read_schema(file_path)
print("所有欄位名稱：", schema.names)

for field in schema:
    print(f"欄位名: {field.name:<20} 資料型態: {field.type}")

# 方式 2：檢視檔案層級元數據（列數、Row Group 數量、大小）
parquet_file = pq.ParquetFile(file_path)
metadata = parquet_file.metadata
print(f"總筆數: {metadata.num_rows}, Row Groups 數: {metadata.num_row_groups}")
```

#### 方法 B：使用 DuckDB (SQL DESCRIBE)
```python
import duckdb

file_path = "data.parquet"

# 回傳欄位名稱、資料型態、是否可為空等資訊
schema_df = duckdb.sql(f"DESCRIBE SELECT * FROM '{file_path}'").df()
print(schema_df[["column_name", "column_type", "null"]])
```

> 💡 **隨附腳本（最省事）**：直接執行現成腳本，一次輸出欄位清單 + 總筆數 + Row Groups 數（支援 table、json、markdown 格式，精確對齊中文字寬）：
>
> ```bash
> # 方式 1：使用 uv 零配置執行
> uv run scripts/list_parquet_columns.py "<檔案路徑.parquet>" [--limit N] [--format json]
>
> # 方式 2：使用一般 python 執行
> python3 scripts/list_parquet_columns.py "<檔案路徑.parquet>" [--limit N] [--format markdown]
> ```

---

### 配方 2：查詢特定某一筆或特定條件資料（下推過濾 Predicate Pushdown）

絕不要先把整份 Parquet 讀成 Pandas 再做 `df[df['id'] == ...]`，這樣會耗盡記憶體。

#### 方法 A：使用 DuckDB（最推薦，完整 SQL 語法）
DuckDB 會自動分析 WHERE 條件，只自磁碟讀取符合條件的 Row Groups 與需要的欄位：

```python
import duckdb

file_path = "data.parquet"
target_id = 10023

# 直接以 SQL 進行查詢
df = duckdb.sql(f"""
    SELECT user_id, user_name, email, created_at
    FROM '{file_path}'
    WHERE user_id = {target_id}
    LIMIT 1
""").df()

if not df.empty:
    print("找到目標資料：")
    print(df.iloc[0].to_dict())
else:
    print("查無此資料")
```

#### 方法 B：使用 PyArrow（標準 API）
```python
import pyarrow.parquet as pq

file_path = "data.parquet"

# filters 格式：[(欄位, 運算子, 數值)]，運算子支援 ==, =, !=, <, >, in 等
filters = [("user_id", "==", 10023)]

table = pq.read_table(
    file_path,
    columns=["user_id", "user_name", "email"],  # 僅讀取指定欄位（投影下推）
    filters=filters                              # 條件下推過濾
)

df = table.to_pandas()
print(df)
```

#### 方法 C：使用 Polars（Lazy API，適合管線化處理）
```python
import polars as pl

# scan_parquet 是惰性評估（Lazy），不會立刻讀取資料
result = (
    pl.scan_parquet("data.parquet")
    .filter(pl.col("user_id") == 10023)
    .select(["user_id", "user_name", "email"])
    .collect()
)
print(result)
```

> 💡 **隨附腳本（大資料集分頁探索與 SQL 分析）**：條件查詢 + 分頁顯示 + 自訂 SQL 聚合，WHERE 與 SELECT 欄位皆下推至磁碟層級：
>
> ```bash
> # 方式 1：條件查詢與分頁（支援 table, json, jsonl, csv）
> uv run scripts/query_parquet.py "<檔案路徑.parquet 或 glob>" \
>     -c col1,col2 -w "col = 'value'" -o "create_datetime DESC" --page 2 --page-size 20
>
> # 方式 2：自訂完整 SQL 分析（DuckDB 聚合，支援 {src} 佔位符）
> uv run scripts/query_parquet.py "<檔案路徑.parquet>" \
>     -q "SELECT status, COUNT(*) AS count FROM {src} GROUP BY status ORDER BY count DESC"
>
> # 方式 3：串流輸出 JSONL 並配合 jq 處理
> uv run scripts/query_parquet.py "dataset/*.parquet" -c user_id,email --format jsonl | jq -c .
> ```
>
> 支援 `--format table|json|jsonl|csv`、`--no-count`（超大資料跳過總數統計）、多檔案 glob、自訂 `-q/--query`。
> ⚠️ **分頁務必搭配 `-o/--order-by`**，否則各頁列順序可能不一致。

---

### 配方 3：寫入 Parquet 檔案與壓縮最佳化

#### 使用 PyArrow 寫入
```python
import pyarrow as pa
import pyarrow.parquet as pq
import pandas as pd

df = pd.DataFrame({
    "user_id": [10001, 10002, 10003],
    "user_name": ["Alice", "Bob", "Charlie"],
    "score": [95.5, 88.0, 72.3]
})

table = pa.Table.from_pandas(df)

# 推薦壓縮演算法：
# - 'snappy'：預設，解壓縮極快，CPU 負擔最低
# - 'zstd'：高壓縮率，適合儲存歷史冷資料或大檔案
pq.write_table(
    table,
    "output.parquet",
    compression="zstd",
    compression_level=7,
    row_group_size=50000  # 依資料量切分 Row Group，便於未來下推查詢
)
```

#### 分區儲存（Hive-style Partitioning）
當資料量極大時，按欄位分目錄儲存（如 `year/month`），讀取特定分區可跳過其他目錄：
```python
pq.write_to_dataset(
    table,
    root_path="partitioned_data/",
    partition_cols=["year", "month"],
    compression="snappy"
)
```

---

### 配方 4：Excel (.xlsx) 批次轉存 Parquet

原始資料常以 Excel 交付，轉成 Parquet 後查詢快數倍且檔案更小。隨附腳本具備自動清理 Sheet 名稱特殊字元（防路徑崩潰）與空表過濾：

```bash
# 預覽目錄內所有 xlsx 的 sheet 結構（毫秒級預覽，不寫入）
uv run scripts/xlsx_to_parquet.py "<目錄>" --dry-run

# 批次轉換整個目錄（全部 sheet），輸出到獨立目錄、zstd 壓縮
uv run scripts/xlsx_to_parquet.py "<目錄>" -o "parquet_out/" --compression zstd

# 只轉資料 sheet，並自動跳過空 sheet
uv run scripts/xlsx_to_parquet.py "data.xlsx" --sheet "Log資料" --skip-empty
```

命名規則：單一 sheet → `<stem>.parquet`；多 sheet 未指定 `--sheet` → 每個 sheet 一檔 `<stem>__<安全sheet名>.parquet`。單檔失敗不中斷批次，會標記 `[失敗]` 繼續。

---

### 配方 5：CSV 批次轉存 Parquet（單一檔案過大 → 流式分片）

CSV 是行式格式且無壓縮，檔案過大時直接 `pd.read_csv()` 全載入會爆記憶體。隨附腳本以 **chunksize 流式讀取**，逐塊寫出多個 Parquet part——記憶體佔用僅與單塊大小（`--rows-per-file`）有關，與檔案總大小無關：

```bash
# 快速預覽 CSV 結構與分片預估（二進位行掃描，秒級響應，不寫入）
uv run scripts/csv_to_parquet.py "<目錄>" --dry-run

# 80MB 單檔轉 Parquet，每 5 萬列一個 part、zstd 壓縮
uv run scripts/csv_to_parquet.py "202608_Log.csv" --rows-per-file 50000 --compression zstd

# 批次轉換目錄內所有 CSV（自動型別推斷、big5 編碼、容錯髒位元組）
uv run scripts/csv_to_parquet.py "dataset/" -o "parquet_out/" --type-mode auto --encoding big5 --encoding-errors replace
```

命名規則：單一分片 → `<stem>.parquet`；多分片 → `<stem>_part000.parquet, _part001.parquet ...`（讀取時用 glob 或 DuckDB 直接查目錄即可合併查詢，見配方 2）。

> 💡 **型別推斷指南**：
> - `--type-mode str`（預設）：全字串讀取，對包含混合型別的「髒日誌」最穩健。
> - `--type-mode auto`：啟用自動型別推斷，適合乾淨業務資料表，可保留數值/時間的 Min/Max 下推過濾優勢與更高壓縮比。

---

## 3. 最佳實踐與避坑指南

1. **避免全量 `pd.read_parquet('huge.parquet')`**：
   若檔案大於可用記憶體，務必使用 `columns=[...]` 搭配 `filters=[...]`，或使用 DuckDB / Polars Lazy 查詢。
2. **謹慎處理字串欄位與 PyArrow String / LargeString**：
   在 Pandas 2.0+ 中建議啟用 `dtype_backend="pyarrow"`，可節省超過 50% 記憶體。
3. **多檔案 Glob 查詢**：
   DuckDB 與 PyArrow 皆原生支援多檔案與萬用字元：
   ```python
   duckdb.sql("SELECT * FROM 'logs/2026/*.parquet' WHERE status = 500")
   ```
4. **DuckDB API 小坑（1.5.x 實測）**：
   - `DESCRIBE SELECT * FROM 'file.parquet'` 回傳 **6 欄**（column_name, column_type, null, key, default, extra），取前三個即可。
   - `parquet_metadata()` 每列是 row group × column chunk，**沒有 num_rows 欄位**；Row Group 數用 `COUNT(DISTINCT row_group_id)`。
   - Parquet 檔案本身**不支援逐欄 comment/註解**；欄位語義說明只能存在於檔案層級 key-value metadata（如 pandas schema JSON）或外部文件。

---

## 資源

- [scripts/list_parquet_columns.py](./scripts/list_parquet_columns.py) — 列出欄位名稱 / 資料型態 / 可為空 + 總筆數 + Row Groups 數（僅讀 Metadata，支援 table/json/markdown，支援 uv run 零依賴執行）
- [scripts/query_parquet.py](./scripts/query_parquet.py) — 條件查詢 + 分頁顯示 + 自訂 SQL 查詢（WHERE / SELECT 下推、table/json/jsonl/csv 輸出、glob 多檔案；支援 uv run 零依賴執行）
- [scripts/xlsx_to_parquet.py](./scripts/xlsx_to_parquet.py) — Excel 批次轉 Parquet（目錄/glob/多檔、指定 sheet、snappy/zstd、Row Group 設定、防非法路徑崩潰、秒級 dry-run；支援 uv run 零依賴執行）
- [scripts/csv_to_parquet.py](./scripts/csv_to_parquet.py) — CSV 批次轉 Parquet（流式分片 `--rows-per-file`、多 part 輸出、`--type-mode auto/str`、編碼容錯、秒級二進位 dry-run；支援 uv run 零依賴執行）
