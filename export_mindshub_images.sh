#!/bin/bash

# =============================================================================
# 匯出 Mindshub Docker Image 腳本
# 用途: 將 docker-compose.dev.yml 使用的 image 分別匯出為獨立的 tar.gz 檔案
#       輸出至 download_deps/images/mindshub/（若目錄不存在會自動建立）
#       供離線環境載入使用
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 適配: mindshub fork 位於 workspace 根 (github/) 下，image tarball 輸出至 workspace 內的 download_deps/
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IMAGES_DIR="${REPO_ROOT}/download_deps/images/mindshub"

# Image 清單 (格式: "repository:tag|basename")
IMAGE_LIST=(
    # web service 直接使用 (docker-compose.dev.yml)
    "node:22-slim|node-22-slim"
    # api service build base image (Dockerfile.api.dev FROM python:3.12-slim)
    "python:3.12-slim|python-3.12-slim"
)

# 建立 images 目錄（若不存在）
mkdir -p "${IMAGES_DIR}"

echo "=========================================="
echo " Mindshub Docker Image 匯出工具"
echo "=========================================="
echo ""
echo "下載清單:"
for i in "${!IMAGE_LIST[@]}"; do
    IFS='|' read -r image basename <<< "${IMAGE_LIST[$i]}"
    echo "  [$((i+1))] ${image} -> ${basename}.tar.gz"
done
echo ""
echo "輸出目錄: ${IMAGES_DIR}"
echo ""

# 檢查 Docker 是否運行
if ! docker info > /dev/null 2>&1; then
    echo "[錯誤] Docker 未運行或無權限，請確認 Docker 服務已啟動"
    exit 1
fi

# 拉取所有 images
echo "[步驟 1/3] 開始拉取 Docker images..."
for entry in "${IMAGE_LIST[@]}"; do
    IFS='|' read -r image basename <<< "$entry"
    if ! docker image inspect "${image}" > /dev/null 2>&1; then
        echo "  [提示] Image '${image}' 不存在，正在拉取..."
        docker pull "${image}"
    else
        echo "  [OK] Image '${image}' 已存在"
    fi
done

# 分別匯出每個 image
echo ""
echo "[步驟 2/3] 開始匯出 Docker images..."
EXPORTED_FILES=()
for entry in "${IMAGE_LIST[@]}"; do
    IFS='|' read -r image basename <<< "$entry"
    output_file="${IMAGES_DIR}/${basename}.tar.gz"
    echo "  匯出 '${image}' -> ${basename}.tar.gz"
    docker save "${image}" | gzip > "${output_file}"
    EXPORTED_FILES+=("${output_file}")
done

# 產生 sha256 checksum（與 images/ 目錄既有慣例一致）
echo ""
echo "[步驟 3/3] 產生 sha256 checksum..."
for output_file in "${EXPORTED_FILES[@]}"; do
    echo "  計算 ${output_file}.sha256"
    sha256sum "${output_file}" > "${output_file}.sha256"
done

# 顯示檔案大小
echo ""
echo "[完成] Images 已成功匯出"
echo "  輸出目錄: ${IMAGES_DIR}"
echo ""
echo "images/mindshub/ 目錄內容:"
ls -lh "${IMAGES_DIR}/"
echo ""
echo "=========================================="
echo " 下一步: 在離線環境執行以下指令載入 image"
for entry in "${IMAGE_LIST[@]}"; do
    IFS='|' read -r image basename <<< "$entry"
    echo "   gunzip -c ${IMAGES_DIR}/${basename}.tar.gz | docker load"
done
echo "=========================================="
