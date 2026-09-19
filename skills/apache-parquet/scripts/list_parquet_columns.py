#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "duckdb>=0.9.0",
# ]
# ///
"""列出 Parquet 檔案的欄位名稱與資料型態（DuckDB DESCRIBE，僅讀 Metadata）

零資料加載：只讀取 Parquet 尾部的 Metadata，不會把任何資料載入記憶體。

用法:
    python3 list_parquet_columns.py <path/to/file.parquet> [options]
    # 或透過 uv 零配置執行：
    uv run list_parquet_columns.py <path/to/file.parquet> [options]

選項:
    --limit N               只顯示前 N 個欄位
    --format {table,json,markdown}
                            輸出格式（預設 table，json 方便 Agent 與腳本解析）

範例:
    python3 list_parquet_columns.py "dataset/202608_Log.parquet"
    python3 list_parquet_columns.py "dataset/202608_Log.parquet" --limit 10
    python3 list_parquet_columns.py "dataset/202608_Log.parquet" --format json
"""

from __future__ import annotations

import argparse
import glob as _glob
import json
import sys
import unicodedata
from pathlib import Path

try:
    import duckdb
except ImportError:
    duckdb = None  # type: ignore


def _quote(path: str) -> str:
    """SQL 字串常數轉義（路徑含單引號時加倍）。"""
    return str(path).replace("'", "''")


def _display_width(s: str) -> int:
    """計算字串在終端的顯示寬度（全形 CJK 寬度計為 2，半形計為 1）。"""
    w = 0
    for ch in str(s):
        w += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
    return w


def _pad_string(s: str, target_width: int, align: str = "left") -> str:
    """依據終端顯示寬度進行對齊填充。"""
    s_str = str(s)
    pad = max(0, target_width - _display_width(s_str))
    if align == "right":
        return " " * pad + s_str
    return s_str + " " * pad


def list_columns(source: str, limit: int | None = None, fmt: str = "table") -> None:
    """使用 DuckDB DESCRIBE / parquet_metadata 僅讀取 Metadata，列出欄位名稱與資料型態。"""
    if duckdb is None:
        raise RuntimeError("尚未安裝 duckdb 套件。請執行 'uv pip install duckdb' 或 'pip install duckdb' 安裝。")

    p = Path(source)
    if not p.is_file() and not p.is_dir() and not _glob.glob(source):
        raise FileNotFoundError(f"找不到符合的 Parquet 檔案或目錄：{source}")

    con = duckdb.connect()
    try:
        quoted_src = _quote(source)
        # DESCRIBE SELECT * FROM '<path>' 僅讀取 Metadata，零資料加載
        # DESCRIBE 回傳 6 欄（column_name, column_type, null, key, default, extra），取前三個
        schema_rows = [
            row[:3] for row in con.execute(f"DESCRIBE SELECT * FROM '{quoted_src}'").fetchall()
        ]

        num_row_groups = None
        total_rows = None
        try:
            total_rows = con.execute(f"SELECT COUNT(*) FROM '{quoted_src}'").fetchone()[0]
            if p.is_file():
                num_row_groups = con.execute(
                    f"SELECT COUNT(DISTINCT row_group_id) FROM parquet_metadata('{quoted_src}')"
                ).fetchone()[0]
        except Exception:
            pass
    finally:
        con.close()

    shown = schema_rows if limit is None else schema_rows[:limit]

    if fmt == "json":
        result = {
            "source": str(source),
            "total_rows": total_rows,
            "num_row_groups": num_row_groups,
            "total_columns": len(schema_rows),
            "shown_columns": len(shown),
            "columns": [
                {
                    "index": i,
                    "name": name,
                    "type": ctype,
                    "nullable": str(nullable).upper() == "YES",
                }
                for i, (name, ctype, nullable) in enumerate(shown, start=1)
            ],
        }
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return

    if fmt == "markdown":
        suffix = f"（前 {len(shown)} / {len(schema_rows)} 欄）" if limit and len(shown) < len(schema_rows) else ""
        meta_info = f"總筆數：{total_rows}"
        if num_row_groups is not None:
            meta_info += f"，Row Groups 數：{num_row_groups}"
        print(f"### Parquet Schema: `{source}`\n")
        print(f"- {meta_info}")
        print(f"- 欄位總數：{len(schema_rows)}{suffix}\n")
        print("| # | 欄位名稱 | 資料型態 | 可為空 |")
        print("|---|---|---|---|")
        for i, (name, ctype, nullable) in enumerate(shown, start=1):
            nullable_cn = "是" if str(nullable).upper() == "YES" else "否"
            print(f"| {i} | {name} | {ctype} | {nullable_cn} |")
        return

    # fmt == "table" (預設終端排版，精確計算中英文顯示寬度)
    col_idx_header = "#"
    col_name_header = "欄位名稱"
    col_type_header = "資料型態"
    col_null_header = "可為空"

    name_w = max(max((_display_width(name) for name, _, _ in shown), default=10), _display_width(col_name_header))
    type_w = max(max((_display_width(ctype) for _, ctype, _ in shown), default=8), _display_width(col_type_header))
    idx_w = max(3, len(str(len(shown))))

    print(f"檔案：{source}")
    info_parts = []
    if total_rows is not None:
        info_parts.append(f"總筆數：{total_rows}")
    if num_row_groups is not None:
        info_parts.append(f"Row Groups 數：{num_row_groups}")
    if info_parts:
        print("，".join(info_parts))

    suffix = f"（前 {len(shown)} / {len(schema_rows)}）" if limit and len(shown) < len(schema_rows) else ""
    print(f"欄位數：{len(schema_rows)}{suffix}\n")

    h_idx = _pad_string(col_idx_header, idx_w, align="right")
    h_name = _pad_string(col_name_header, name_w)
    h_type = _pad_string(col_type_header, type_w)
    print(f"{h_idx}  {h_name}  {h_type}  {col_null_header}")
    print("-" * (idx_w + 2 + name_w + 2 + type_w + 2 + _display_width(col_null_header)))

    for i, (name, ctype, nullable) in enumerate(shown, start=1):
        nullable_cn = "是" if str(nullable).upper() == "YES" else "否"
        s_idx = _pad_string(str(i), idx_w, align="right")
        s_name = _pad_string(name, name_w)
        s_type = _pad_string(ctype, type_w)
        print(f"{s_idx}  {s_name}  {s_type}  {nullable_cn}")


def main() -> int:
    parser = argparse.ArgumentParser(description="列出 Parquet 檔案的欄位名稱（DuckDB，僅讀 Metadata）")
    parser.add_argument("source", help="Parquet 檔案路徑或目錄")
    parser.add_argument("--limit", type=int, default=None, help="只顯示前 N 個欄位")
    parser.add_argument(
        "--format",
        choices=["table", "json", "markdown"],
        default="table",
        help="輸出格式：table（預設）/ json / markdown",
    )
    args = parser.parse_args()

    try:
        list_columns(args.source, limit=args.limit, fmt=args.format)
    except (FileNotFoundError, RuntimeError) as e:
        print(f"錯誤：{e}", file=sys.stderr)
        return 1
    except duckdb.Error as e:
        print(f"DuckDB 錯誤：{e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
