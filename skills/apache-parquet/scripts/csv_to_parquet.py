#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "pandas>=2.0.0",
#     "pyarrow>=14.0.0",
# ]
# ///
"""批次將 CSV 轉存為 Parquet（pandas + PyArrow，流式分片）

針對「單一檔案過大」場景：以 chunksize 流式讀取，逐塊寫出多個 Parquet part，
記憶體佔用僅與單塊大小有關，與檔案總大小無關。

用法:
    python3 csv_to_parquet.py <目錄 | glob | file.csv ...> [options]
    # 或透過 uv 零配置執行：
    uv run csv_to_parquet.py <目錄 | glob | file.csv ...> [options]

選項:
    -o, --output-dir DIR      輸出目錄（預設：與來源檔案同目錄）
        --rows-per-file N     每個 Parquet part 的列數（預設 100000；流式分片大小）
        --type-mode MODE      型別模式：str（預設，所有欄位視為字串，髒資料最穩）/ auto（自動推斷型別，保留數值下推與壓縮）
        --compression C       snappy（預設，解壓最快）/ zstd（壓縮率較高，適合冷資料）
        --row-group-size N    Row Group 大小（預設 50000，便於日後下推查詢）
        --encoding ENC        CSV 編碼（預設 utf-8-sig，可自動處理 BOM；常見：big5、gb18030）
        --encoding-errors ERR 編碼錯誤處理：replace（預設，容錯髒資料）/ ignore / strict
        --sep CHAR            分隔字元（預設 ,）
    -r, --recursive           遞迴搜尋子目錄內的 .csv 檔案
        --dry-run             只列出檔案與結構資訊（欄位數、列數），不寫入

輸出命名規則:
    - 單一分片（資料量 <= rows-per-file）→ <stem>.parquet
    - 多分片                              → <stem>_part000.parquet, _part001.parquet ...
      （讀取時用 glob "<stem>_part*.parquet" 或 DuckDB 直接查目錄即可合併查詢）

範例:
    # 預覽 CSV 結構（不寫入）
    python3 csv_to_parquet.py "dataset/" --dry-run

    # 80MB 單檔轉 Parquet，每 5 萬列一個 part、zstd 壓縮
    python3 csv_to_parquet.py "202608_Log.csv" --rows-per-file 50000 --compression zstd

    # 批次轉換目錄內所有 CSV（自動型別推斷、big5 編碼）
    python3 csv_to_parquet.py "dataset/" -o "parquet_out/" --type-mode auto --encoding big5
"""

from __future__ import annotations

import argparse
import glob as _glob
import sys
import time
from pathlib import Path

try:
    import pandas as pd
except ImportError:
    pd = None  # type: ignore


def find_sources(inputs: list[str], recursive: bool = False) -> list[Path]:
    """將目錄 / glob / 檔案參數展開為 .csv 清單（去重、保持順序）。"""
    found: list[Path] = []
    for raw in inputs:
        p = Path(raw)
        if p.is_dir():
            pattern = "**/*.csv" if recursive else "*.csv"
            candidates = sorted(p.glob(pattern))
        elif p.is_file():
            candidates = [p]
        elif any(ch in raw for ch in "*?["):
            candidates = [Path(x) for x in sorted(_glob.glob(raw, recursive=recursive))]
        else:
            candidates = [p]
        for c in candidates:
            if c.suffix.lower() != ".csv":
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


def _quick_count_lines(path: Path) -> int:
    """快速以二進位區塊掃描換行符統計檔案行數（扣除表頭 1 列）。"""
    lines = 0
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b""):
                lines += chunk.count(b"\n")
        return max(0, lines - 1)
    except Exception:
        return 0


def convert_file(
    path: Path,
    output_dir: Path | None,
    rows_per_file: int,
    type_mode: str,
    compression: str,
    row_group_size: int,
    encoding: str,
    encoding_errors: str,
    sep: str,
    dry_run: bool,
) -> tuple[int, int]:
    """流式轉換單一 CSV，回傳 (寫入檔數, 總列數)。"""
    out_dir = output_dir or path.parent

    # 僅讀表頭取得欄位資訊（nrows=0，開銷微秒級）
    header = pd.read_csv(
        path,
        nrows=0,
        encoding=encoding,
        encoding_errors=encoding_errors,
        sep=sep,
    )
    n_cols = len(header.columns)

    if dry_run:
        total_rows = _quick_count_lines(path)
        print(f"● {path.name}（{human_size(path.stat().st_size)}）")
        print(f"    [dry-run] 約 {total_rows:,} 列 × {n_cols} 欄，encoding={encoding}, type_mode={type_mode}")
        n_parts = (total_rows + rows_per_file - 1) // rows_per_file if total_rows else 0
        name = f"{path.stem}.parquet" if n_parts <= 1 else f"{path.stem}_part*.parquet"
        print(f"    [dry-run] 將產生 {n_parts} 個 Parquet → {name}")
        return max(n_parts, 0), total_rows

    # 依 type_mode 決定型別策略：str 為日誌安全模式，auto 啟用自動推斷
    read_dtype = str if type_mode == "str" else None

    reader = pd.read_csv(
        path,
        chunksize=rows_per_file,
        encoding=encoding,
        encoding_errors=encoding_errors,
        sep=sep,
        dtype=read_dtype,
    )
    total_rows = 0
    parts: list[Path] = []
    t0 = time.perf_counter()

    for i, chunk in enumerate(reader):
        total_rows += len(chunk)
        # 先以暫定 part 名稱寫出；若最終只有一個分片，再改名為 <stem>.parquet
        out_path = out_dir / f"{path.stem}_part{i:03d}.parquet"
        chunk.to_parquet(
            out_path,
            engine="pyarrow",
            compression=compression,
            row_group_size=row_group_size,
            index=False,
        )
        parts.append(out_path)

    # 單分片時改名為 <stem>.parquet（與 xlsx_to_parquet.py 命名一致）
    if len(parts) == 1:
        single = out_dir / f"{path.stem}.parquet"
        if single.exists() and single != parts[0]:
            single.unlink()
        parts[0].rename(single)
        parts = [single]

    elapsed = time.perf_counter() - t0
    total_mb = sum(p.stat().st_size for p in parts) / 1e6
    print(f"● {path.name}（{human_size(path.stat().st_size)}）")
    if len(parts) == 1:
        print(f"    {total_rows:,} 列 × {n_cols} 欄 → {parts[0].name}（{total_mb:.1f} MB, {elapsed:.1f}s）")
    else:
        print(f"    {total_rows:,} 列 × {n_cols} 欄 → {len(parts)} 個 part（{path.stem}_part*.parquet，共 {total_mb:.1f} MB, {elapsed:.1f}s）")
    return len(parts), total_rows


def main() -> int:
    parser = argparse.ArgumentParser(description="批次將 CSV 轉存為 Parquet（pandas + PyArrow，流式分片）")
    parser.add_argument("sources", nargs="+", help="目錄、glob 或 .csv 檔案（可多個）")
    parser.add_argument("-o", "--output-dir", type=Path, default=None, help="輸出目錄（預設與來源同目錄）")
    parser.add_argument("--rows-per-file", type=int, default=100_000, help="每個 Parquet part 的列數（預設 100000）")
    parser.add_argument(
        "--type-mode",
        choices=["str", "auto"],
        default="str",
        help="型別模式：str（預設，所有欄位轉字串，髒資料最穩健）/ auto（自動推斷型別）",
    )
    parser.add_argument("--compression", choices=["snappy", "zstd"], default="snappy", help="壓縮演算法（預設 snappy）")
    parser.add_argument("--row-group-size", type=int, default=50_000, help="Row Group 大小（預設 50000）")
    parser.add_argument("--encoding", default="utf-8-sig", help="CSV 編碼（預設 utf-8-sig，可處理 BOM）")
    parser.add_argument(
        "--encoding-errors",
        choices=["replace", "ignore", "strict"],
        default="replace",
        help="編碼錯誤處理方式（預設 replace，防止髒資料報錯中斷）",
    )
    parser.add_argument("--sep", default=",", help="分隔字元（預設 ,）")
    parser.add_argument("-r", "--recursive", action="store_true", help="遞迴搜尋子目錄中的 CSV 檔案")
    parser.add_argument("--dry-run", action="store_true", help="只列出檔案與結構資訊，不寫入")
    args = parser.parse_args()

    if args.rows_per_file < 1 or args.row_group_size < 1:
        print("錯誤：--rows-per-file 與 --row-group-size 必須 >= 1", file=sys.stderr)
        return 2

    if pd is None:
        print("錯誤：尚未安裝 pandas/pyarrow 套件。請執行 'uv pip install pandas pyarrow' 或 'pip install pandas pyarrow' 安裝。", file=sys.stderr)
        return 1

    try:
        files = find_sources(args.sources, recursive=args.recursive)
    except FileNotFoundError as e:
        print(f"錯誤：{e}", file=sys.stderr)
        return 1
    if not files:
        print("錯誤：找不到任何 .csv 檔案", file=sys.stderr)
        return 1

    if args.output_dir and not args.dry_run:
        args.output_dir.mkdir(parents=True, exist_ok=True)

    mode = "預覽（--dry-run）" if args.dry_run else f"轉換（compression={args.compression}, type_mode={args.type_mode}, rows_per_file={args.rows_per_file:,}）"
    print(f"共 {len(files)} 個 csv | {mode}\n")

    t0 = time.perf_counter()
    total_parts = total_rows = failed = 0
    for i, f in enumerate(files):
        try:
            p, r = convert_file(
                f,
                args.output_dir,
                args.rows_per_file,
                args.type_mode,
                args.compression,
                args.row_group_size,
                args.encoding,
                args.encoding_errors,
                args.sep,
                args.dry_run,
            )
            total_parts += p
            total_rows += r
        except SystemExit:
            raise
        except Exception as e:  # 單檔失敗不中斷批次
            print(f"    [失敗] {f.name}: {e}", file=sys.stderr)
            failed += 1
        if i < len(files) - 1:
            print()

    elapsed = time.perf_counter() - t0
    verb = "將產生" if args.dry_run else "已寫入"
    suffix = f"，{failed} 個失敗" if failed else ""
    print(f"\n完成：{verb} {total_parts} 個 Parquet（共 {total_rows:,} 列），耗時 {elapsed:.1f}s{suffix}")
    return 1 if failed and not args.dry_run else 0


if __name__ == "__main__":
    raise SystemExit(main())
