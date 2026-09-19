#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "duckdb>=0.9.0",
# ]
# ///
"""分頁 / 條件查詢 Parquet 資料（DuckDB，下推過濾 + 欄位投影）

利用 DuckDB 的 Predicate Pushdown：WHERE 條件與 SELECT 欄位皆下推至磁碟層級，
只讀取符合條件的 Row Groups 與需要的欄位，適合探索大資料集而不全載入記憶體。

用法:
    python3 query_parquet.py <path/to/file.parquet 或 glob> [options]
    # 或透過 uv 零配置執行：
    uv run query_parquet.py <path/to/file.parquet 或 glob> [options]

選項:
    -c, --columns COLS      逗號分隔的欄位清單（投影下推，寬表建議指定）
    -w, --where COND        SQL WHERE 條件（過濾下推），例：login_success = 'false'
    -o, --order-by SPEC     排序規格，例："create_datetime DESC"（分頁穩定性必需）
    -q, --query SQL         自訂完整 SQL 查詢（可使用 {src} 代表資料源），指定此選項時忽略 -c/-w/-o
        --page N            頁碼（由 1 起，預設 1）
        --page-size N       每頁列數（預設 20）
        --no-count          跳過總筆數統計（超大資料更快，但不顯示總頁數）
        --format FMT        輸出格式：table（預設）/ json / jsonl / csv
        --max-width N       table 模式單格最大寬度（超出截斷，預設 40；json/csv 不截斷）

範例:
    # 看前 20 列的指定欄位
    python3 query_parquet.py "dataset/202608_Log.parquet" -c create_datetime,account_id,login_success

    # 條件查詢 + 分頁：第 2 頁、每頁 10 列（建議搭配 --order-by）
    python3 query_parquet.py "dataset/202608_Log.parquet" \
        -w "login_success = 'false'" -o "create_datetime DESC" --page 2 --page-size 10

    # 自訂 SQL 分析（聚合統計）
    python3 query_parquet.py "dataset/202608_Log.parquet" \
        -q "SELECT status, COUNT(*) as cnt FROM {src} GROUP BY status ORDER BY cnt DESC"

    # 多檔案 glob + JSONL 輸出（可直接 pipe 給 jq 或串流處理）
    python3 query_parquet.py "dataset/*.parquet" -c udid,account_id --format jsonl | jq -c .

注意：分頁時務必指定 --order-by，否則各頁的列順序可能不一致。
"""

from __future__ import annotations

import argparse
import csv
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


def check_source(pattern: str) -> None:
    """驗證檔案 / glob / 目錄存在（DuckDB 亦可直接讀取 Parquet 目錄）。"""
    p = Path(pattern)
    if p.is_file() or p.is_dir():
        return
    if not _glob.glob(pattern):
        raise FileNotFoundError(f"找不到符合的 Parquet 檔案或目錄：{pattern}")


def run_query(
    con: duckdb.DuckDBPyConnection,
    source: str,
    columns: list[str] | None,
    where: str | None,
    order_by: str | None,
    custom_query: str | None,
    page: int,
    page_size: int,
    do_count: bool,
):
    """執行分頁查詢或自訂查詢，回傳 (total|None, headers, rows)。"""
    from_sql = f"'{_quote(source)}'"

    if custom_query:
        # 使用者傳入自訂完整 SQL
        sql_base = custom_query.replace("{src}", from_sql).replace("{source}", from_sql)
        total = None
        if do_count:
            try:
                count_sql = f"SELECT COUNT(*) FROM ({sql_base}) AS _sub"
                total = con.execute(count_sql).fetchone()[0]
            except Exception:
                pass
        offset = (page - 1) * page_size
        paged_sql = f"SELECT * FROM ({sql_base}) AS _sub LIMIT ? OFFSET ?"
        result = con.execute(paged_sql, [page_size, offset])
        headers = [d[0] for d in result.description]
        rows = result.fetchall()
        return total, headers, rows

    cols_sql = ", ".join(columns) if columns else "*"
    where_sql = f" WHERE {where}" if where else ""

    total = None
    if do_count:
        # COUNT(*) 僅為統計，DuckDB 可利用 Row Group statistics 加速
        total = con.execute(f"SELECT COUNT(*) FROM {from_sql}{where_sql}").fetchone()[0]

    offset = (page - 1) * page_size
    sql = f"SELECT {cols_sql} FROM {from_sql}{where_sql}"
    if order_by:
        sql += f" ORDER BY {order_by}"
    sql += " LIMIT ? OFFSET ?"

    result = con.execute(sql, [page_size, offset])
    headers = [d[0] for d in result.description]
    rows = result.fetchall()
    return total, headers, rows


def _clip(value, max_width: int):
    if isinstance(value, str) and len(value) > max_width:
        return value[: max_width - 1] + "…"
    return value


def print_table(headers: list[str], rows: list[tuple], max_width: int) -> None:
    if not headers:
        return
    cells = [
        ["" if c is None else str(_clip(c, max_width)) for c in row] for row in rows
    ]
    widths = [
        max(_display_width(h), *( _display_width(r[i]) for r in cells )) if cells else _display_width(h)
        for i, h in enumerate(headers)
    ]
    print("  ".join(_pad_string(h, w) for h, w in zip(headers, widths)))
    total_w = sum(widths) + 2 * (len(widths) - 1)
    print("-" * total_w)
    for r in cells:
        print("  ".join(_pad_string(c, w) for c, w in zip(r, widths)))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="分頁 / 條件查詢 Parquet（DuckDB，下推過濾 + 欄位投影）"
    )
    parser.add_argument("source", help="Parquet 檔案路徑、glob 或目錄")
    parser.add_argument("-c", "--columns", default=None, help="逗號分隔的欄位清單（投影下推）")
    parser.add_argument("-w", "--where", default=None, help="SQL WHERE 條件（過濾下推）")
    parser.add_argument("-o", "--order-by", default=None, help='排序規格，例："create_datetime DESC"')
    parser.add_argument(
        "-q",
        "--query",
        default=None,
        help="自訂 SQL 查詢語句（支援 {src} 佔位符），指定此選項時將忽略 -c, -w, -o",
    )
    parser.add_argument("--page", type=int, default=1, help="頁碼（由 1 起，預設 1）")
    parser.add_argument("--page-size", type=int, default=20, help="每頁列數（預設 20）")
    parser.add_argument("--no-count", action="store_true", help="跳過總筆數統計（超大資料更快）")
    parser.add_argument(
        "--format",
        choices=["table", "json", "jsonl", "csv"],
        default="table",
        help="輸出格式：table（預設）/ json / jsonl / csv",
    )
    parser.add_argument("--max-width", type=int, default=40, help="table 模式單格最大寬度（預設 40）")
    args = parser.parse_args()

    if args.page < 1 or args.page_size < 1:
        print("錯誤：--page 與 --page-size 必須 >= 1", file=sys.stderr)
        return 2
    columns = [c.strip() for c in args.columns.split(",") if c.strip()] if args.columns else None

    try:
        check_source(args.source)
    except FileNotFoundError as e:
        print(f"錯誤：{e}", file=sys.stderr)
        return 1

    if args.page > 1 and not args.order_by and not args.query:
        print("警告：未指定 --order-by，分頁結果的列順序可能不一致", file=sys.stderr)

    if duckdb is None:
        print("錯誤：尚未安裝 duckdb 套件。請執行 'uv pip install duckdb' 或 'pip install duckdb' 安裝。", file=sys.stderr)
        return 1

    con = duckdb.connect()
    try:
        total, headers, rows = run_query(
            con,
            source=args.source,
            columns=columns,
            where=args.where,
            order_by=args.order_by,
            custom_query=args.query,
            page=args.page,
            page_size=args.page_size,
            do_count=not args.no_count,
        )
    except duckdb.Error as e:
        print(f"SQL 錯誤：{e}", file=sys.stderr)
        return 1
    finally:
        con.close()

    if total is not None:
        pages = (total + args.page_size - 1) // args.page_size if total else 0
        summary = f"符合 {total} 筆 | 第 {args.page}/{max(pages, 1)} 頁 | 本頁 {len(rows)} 列"
    else:
        summary = f"第 {args.page} 頁（每頁 {args.page_size}）| 本頁 {len(rows)} 列（--no-count：未統計總數）"

    if not rows:
        if args.format == "table":
            print(summary)
            print("查無符合條件的資料")
        elif args.format == "json":
            print("[]")
        return 0

    if args.format == "table":
        print(summary)
        print()
        print_table(headers, rows, args.max_width)
    elif args.format == "json":
        records = [dict(zip(headers, row)) for row in rows]
        print(json.dumps(records, ensure_ascii=False, indent=2, default=str))
    elif args.format == "jsonl":
        for row in rows:
            record = dict(zip(headers, row))
            print(json.dumps(record, ensure_ascii=False, default=str))
    else:  # csv
        writer = csv.writer(sys.stdout)
        writer.writerow(headers)
        writer.writerows(rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
