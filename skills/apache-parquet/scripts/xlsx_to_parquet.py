#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "pandas>=2.0.0",
#     "openpyxl>=3.1.0",
#     "pyarrow>=14.0.0",
# ]
# ///
"""批次將 Excel (.xlsx) 轉存為 Parquet（pandas + PyArrow）

支援目錄 / glob / 多檔案一次轉換；每個 sheet 可獨立輸出，並附壓縮與 Row Group 設定。
自動過濾 Sheet 名稱中的非法字元（如 / \ 等），防止子路徑錯誤崩潰。

用法:
    python3 xlsx_to_parquet.py <目錄 | glob | file.xlsx ...> [options]
    # 或透過 uv 零配置執行：
    uv run xlsx_to_parquet.py <目錄 | glob | file.xlsx ...> [options]

選項:
    -o, --output-dir DIR      輸出目錄（預設：與來源檔案同目錄）
        --sheet NAME|IDX      只轉換指定 sheet（名稱或 0-based 索引）；預設全部 sheet
        --compression C       snappy（預設，解壓最快）/ zstd（壓縮率較高，適合冷資料）
        --row-group-size N    Row Group 大小（預設 50000，便於日後下推查詢）
        --skip-empty          自動跳過無資料的空白工作表
    -r, --recursive           遞迴搜尋子目錄內的 .xlsx 檔案
        --dry-run             只列出檔案與 sheet 結構資訊（名稱、列數×欄數），不寫入

輸出命名規則:
    - 單一 sheet 工作簿            → <stem>.parquet
    - 多 sheet 且未指定 --sheet    → 每個 sheet 一檔：<stem>__<安全sheet名>.parquet
    - 指定 --sheet                 → <stem>.parquet（僅該 sheet）

範例:
    # 預覽目錄內所有 xlsx 的 sheet 結構（不寫入）
    python3 xlsx_to_parquet.py "dataset/" --dry-run

    # 批次轉換整個目錄（全部 sheet），輸出到獨立目錄
    python3 xlsx_to_parquet.py "dataset/" -o "parquet_out/" --compression zstd

    # 只轉資料 sheet，輸出檔名即 <stem>.parquet
    python3 xlsx_to_parquet.py "202608_Log 1.xlsx" --sheet Log資料
"""

from __future__ import annotations

import argparse
import glob as _glob
import re
import sys
import time
from pathlib import Path

try:
    import pandas as pd
except ImportError:
    pd = None  # type: ignore


def _sanitize_sheet_name(name: str) -> str:
    """清理 Sheet 名稱中的非法字元（如 / \ : * ? " < > | 等），避免作業系統路徑錯誤。"""
    sanitized = re.sub(r'[\\/*?:"<>|\r\n\t]', "_", name).strip()
    return sanitized or "sheet"


def find_sources(inputs: list[str], recursive: bool = False) -> list[Path]:
    """將目錄 / glob / 檔案參數展開為 .xlsx 清單（去重、保持順序）。"""
    found: list[Path] = []
    for raw in inputs:
        p = Path(raw)
        if p.is_dir():
            pattern = "**/*.xlsx" if recursive else "*.xlsx"
            candidates = sorted(p.glob(pattern))
        elif p.is_file():
            candidates = [p]
        elif any(ch in raw for ch in "*?["):
            candidates = [Path(x) for x in sorted(_glob.glob(raw, recursive=recursive))]
        else:
            candidates = [p]
        for c in candidates:
            if c.suffix.lower() != ".xlsx" or c.name.startswith("~$"):  # 忽略 Excel 暫存檔
                continue
            if not c.exists():
                raise FileNotFoundError(f"找不到檔案：{c}")
            if c not in found:
                found.append(c)
    return found


def human_size(nbytes: float) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if nbytes < 1024 or unit == "GB":
            return f"{nbytes:.1f} {unit}" if unit != "B" else f"{int(nbytes)} B"
        nbytes /= 1024
    return f"{nbytes:.1f} GB"


def resolve_sheet(xf: pd.ExcelFile, spec: str | None) -> list[str]:
    """回傳要轉換的 sheet 名稱清單。"""
    if spec is None:
        return xf.sheet_names
    try:
        idx = int(spec)
        if not 0 <= idx < len(xf.sheet_names):
            raise ValueError
        return [xf.sheet_names[idx]]
    except ValueError:
        if spec in xf.sheet_names:
            return [spec]
        valid = ", ".join(f"{i}: {n}" for i, n in enumerate(xf.sheet_names))
        raise SystemExit(f"錯誤：找不到 sheet「{spec}」。可用 sheet → {valid}")


def convert_file(
    path: Path,
    output_dir: Path | None,
    sheet_spec: str | None,
    compression: str,
    row_group_size: int,
    skip_empty: bool,
    dry_run: bool,
) -> tuple[int, int]:
    """轉換單一 xlsx，回傳 (寫入檔數, 總列數)。"""
    xf = pd.ExcelFile(path)
    sheets = resolve_sheet(xf, sheet_spec)
    multi = len(xf.sheet_names) > 1 and sheet_spec is None
    out_dir = output_dir or path.parent

    print(f"● {path.name}（sheets: {', '.join(xf.sheet_names)}）")
    written = total_rows = 0

    if dry_run:
        # 秒級預覽：僅讀取表頭或快速維度，不全量讀取儲存格
        for name in sheets:
            safe_name = _sanitize_sheet_name(name)
            out_name = f"{path.stem}__{safe_name}.parquet" if multi else f"{path.stem}.parquet"
            out_path = out_dir / out_name
            try:
                head_df = pd.read_excel(xf, sheet_name=name, nrows=1)
                n_cols = head_df.shape[1]
                print(f"    [dry-run] {name}（欄數: {n_cols}）→ {out_path.name}")
            except Exception as e:
                print(f"    [dry-run] {name} 讀取失敗: {e}")
            written += 1
        xf.close()
        return written, total_rows

    for name in sheets:
        df = pd.read_excel(xf, sheet_name=name)
        if skip_empty and (df.empty or len(df) == 0):
            print(f"    [略過空表] {name}: 0 列資料")
            continue

        safe_name = _sanitize_sheet_name(name)
        out_name = f"{path.stem}__{safe_name}.parquet" if multi else f"{path.stem}.parquet"
        out_path = out_dir / out_name

        # 針對 Excel 混合型別欄位做安全防護：若 object 欄位包含混合物件，轉成字串防止 PyArrow 序列化崩潰
        for col in df.select_dtypes(include=["object"]).columns:
            df[col] = df[col].apply(lambda v: str(v) if v is not None and not pd.isna(v) else None)

        t0 = time.perf_counter()
        df.to_parquet(
            out_path,
            engine="pyarrow",
            compression=compression,
            row_group_size=row_group_size,
            index=False,
        )
        elapsed = time.perf_counter() - t0
        size = human_size(out_path.stat().st_size)
        print(f"    {name}: {len(df)} 列 × {df.shape[1]} 欄 → {out_path.name}（{size}, {elapsed:.1f}s）")
        written += 1
        total_rows += len(df)

    xf.close()
    return written, total_rows


def main() -> int:
    parser = argparse.ArgumentParser(description="批次將 Excel (.xlsx) 轉存為 Parquet（pandas + PyArrow）")
    parser.add_argument("sources", nargs="+", help="目錄、glob 或 .xlsx 檔案（可多個）")
    parser.add_argument("-o", "--output-dir", type=Path, default=None, help="輸出目錄（預設與來源同目錄）")
    parser.add_argument("--sheet", default=None, help="只轉換指定 sheet（名稱或 0-based 索引）")
    parser.add_argument("--compression", choices=["snappy", "zstd"], default="snappy", help="壓縮演算法（預設 snappy）")
    parser.add_argument("--row-group-size", type=int, default=50000, help="Row Group 大小（預設 50000）")
    parser.add_argument("--skip-empty", action="store_true", help="自動跳過無資料的空白工作表")
    parser.add_argument("-r", "--recursive", action="store_true", help="遞迴搜尋子目錄中的 XLSX 檔案")
    parser.add_argument("--dry-run", action="store_true", help="只列出檔案與 sheet 資訊，不寫入")
    args = parser.parse_args()

    if pd is None:
        print("錯誤：尚未安裝必要套件（pandas, openpyxl, pyarrow）。請執行 'uv pip install pandas openpyxl pyarrow' 或 'pip install pandas openpyxl pyarrow' 安裝。", file=sys.stderr)
        return 1

    try:
        files = find_sources(args.sources, recursive=args.recursive)
    except FileNotFoundError as e:
        print(f"錯誤：{e}", file=sys.stderr)
        return 1
    if not files:
        print("錯誤：找不到任何 .xlsx 檔案", file=sys.stderr)
        return 1

    if args.output_dir and not args.dry_run:
        args.output_dir.mkdir(parents=True, exist_ok=True)

    mode = "預覽（--dry-run）" if args.dry_run else f"轉換（compression={args.compression}）"
    print(f"共 {len(files)} 個 xlsx | {mode}\n")

    t0 = time.perf_counter()
    total_files = total_rows = failed = 0
    for i, f in enumerate(files, start=1):
        try:
            w, r = convert_file(
                f,
                args.output_dir,
                args.sheet,
                args.compression,
                args.row_group_size,
                args.skip_empty,
                args.dry_run,
            )
            total_files += w
            total_rows += r
        except SystemExit:
            raise
        except Exception as e:  # 單檔失敗不中斷批次
            print(f"    [失敗] {f.name}: {e}", file=sys.stderr)
            failed += 1
        if i < len(files):
            print()

    elapsed = time.perf_counter() - t0
    verb = "將產生" if args.dry_run else "已寫入"
    suffix = f"，{failed} 個失敗" if failed else ""
    print(f"\n完成：{verb} {total_files} 個 Parquet（共 {total_rows:,} 列），耗時 {elapsed:.1f}s{suffix}")
    return 1 if failed and not args.dry_run else 0


if __name__ == "__main__":
    raise SystemExit(main())
