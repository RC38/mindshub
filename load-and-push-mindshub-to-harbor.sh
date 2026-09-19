#!/usr/bin/env bash
# =============================================================================
# Mindshub 映像載入並上傳至 Harbor 腳本
# 參考: ../03.flowise/push-flowise-to-harbor.sh、../../Lxd-K8S/05.ApacheHugeGraph/push-hugegraph-to-harbor.sh
#
# 此腳本負責:
# 1. 從 download_deps/images/mindshub/ 載入 tar.gz image (export_mindshub_images.sh 產出)
#    - node-22-slim.tar.gz     -> node:22-slim      (web service 直接使用)
#    - python-3.12-slim.tar.gz -> python:3.12-slim  (api build base image)
# 2. 信任 Harbor 自簽憑證 (寫入 /etc/docker/certs.d/<harbor-host>/ca.crt)
# 3. 透過 Harbor API 建立 Project (若不存在)
# 4. docker tag + docker push 至 Harbor (<project>/mindshub/<repo>:<tag>)
# 5. 驗證上傳結果 (artifacts 端點 + docker pull 回拉)
#
# 使用方式:
#   ./load-and-push-mindshub-to-harbor.sh                                          # 使用預設值
#   ./load-and-push-mindshub-to-harbor.sh <harbor_host:port> <project>
#
# 前提:
#   1. download_deps/images/mindshub/ 下必須有 tar.gz 檔案 (先執行 export_mindshub_images.sh)
#      或本機已有對應 image (載入步驟會自動跳過已存在的 image)
#   2. Harbor 必須已部署且可從宿主機存取 (預設 10.128.224.1:9443)
# =============================================================================

set -euo pipefail

# ─── 顏色定義 ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ─── 變數定義 ───
HARBOR_HOST="${1:-10.128.224.1:9443}"
HARBOR_PROJECT="${2:-lxd-k8s}"
HARBOR_ADMIN_USER="${HARBOR_ADMIN_USER:-admin}"
HARBOR_ADMIN_PASSWORD="${HARBOR_ADMIN_PASSWORD:-Harbor12345}"

MINDSHUB_NAMESPACE="mindshub"
MGMT_CONTAINER="${MGMT_CONTAINER:-rmp-mgmt-docker-01}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 適配: mindshub fork 位於 workspace 根 (github/) 下，與 export_mindshub_images.sh 的輸出位置一致
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IMAGES_DIR="${IMAGES_DIR:-${REPO_ROOT}/download_deps/images/mindshub}"

# Image 清單 (格式: "tar_basename|original_image")
IMAGE_LIST=(
    "node-22-slim.tar.gz|node:22-slim"
    "python-3.12-slim.tar.gz|python:3.12-slim"
)

CERTS_DIR="/etc/docker/certs.d/${HARBOR_HOST}"

log_info "============================================"
log_info "Mindshub 映像載入並上傳至 Harbor"
log_info "============================================"
log_info "Harbor：${HARBOR_HOST}  (project: ${HARBOR_PROJECT})"
log_info "Image 目錄：${IMAGES_DIR}"
echo ""

# ==========================================
# 1. 從 tar.gz 載入 image
# ==========================================
log_info "============================================"
log_info "步驟 1: 載入 Docker images (download_deps/images/mindshub/)"
log_info "============================================"

if [ ! -d "${IMAGES_DIR}" ]; then
    log_error "找不到目錄：${IMAGES_DIR}"
    log_error "請先執行 export_mindshub_images.sh 匯出 image"
fi

LOADED_COUNT=0
SKIPPED_COUNT=0
MISSING_TAR=()
for entry in "${IMAGE_LIST[@]}"; do
    IFS='|' read -r tar_file original_image <<< "$entry"
    tar_path="${IMAGES_DIR}/${tar_file}"

    # 本機已有 image 則跳過載入
    if docker image inspect "${original_image}" &>/dev/null; then
        log_success "Image '${original_image}' 已存在，跳過載入"
        SKIPPED_COUNT=$((SKIPPED_COUNT+1))
        continue
    fi

    # tar.gz 不存在則記錄缺失
    if [ ! -f "${tar_path}" ]; then
        log_warn "找不到檔案：${tar_file}（將嘗試直接推送本機 image，若也不存在則跳過）"
        MISSING_TAR+=("${original_image}")
        continue
    fi

    # 載入 image (gunzip -c | docker load)
    FILE_SIZE=$(du -h "${tar_path}" | cut -f1)
    log_info "載入 '${original_image}' <- ${tar_file} (${FILE_SIZE})..."
    if gunzip -c "${tar_path}" | docker load; then
        log_success "載入成功：${original_image}"
        LOADED_COUNT=$((LOADED_COUNT+1))
    else
        log_error "載入失敗：${tar_file}"
    fi
done

log_info "載入完成：新增 ${LOADED_COUNT} 個、已存在跳過 ${SKIPPED_COUNT} 個"
echo ""

# ==========================================
# 2. 信任 Harbor 自簽憑證
# ==========================================
log_info "============================================"
log_info "步驟 2: 設定 Docker 對 Harbor (${HARBOR_HOST}) 的憑證信任"
log_info "============================================"

NEED_UPDATE_CERT=0

# 檢查 Harbor 當前連線的伺服器憑證 fingerprint
REMOTE_FP=$(openssl s_client -connect "${HARBOR_HOST}" -servername "${HARBOR_HOST%:*}" </dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256 2>/dev/null || echo "")

if [ -f "${CERTS_DIR}/ca.crt" ]; then
    LOCAL_FP=$(openssl x509 -in "${CERTS_DIR}/ca.crt" -noout -fingerprint -sha256 2>/dev/null || echo "")
    if [ -n "${REMOTE_FP}" ] && [ "${REMOTE_FP}" = "${LOCAL_FP}" ]; then
        log_success "本機 Docker 憑證與 Harbor 伺服器一致 (${REMOTE_FP})"
    else
        log_warn "本機憑證與 Harbor 伺服器不一致或失效，將重新同步憑證..."
        NEED_UPDATE_CERT=1
    fi
else
    log_info "本機尚未安裝 Harbor 憑證 (${CERTS_DIR}/ca.crt)，將進行安裝..."
    NEED_UPDATE_CERT=1
fi

if [ "${NEED_UPDATE_CERT}" -eq 1 ]; then
    TMP_CERT="$(mktemp)"
    if lxc file pull "${MGMT_CONTAINER}/opt/harbor/tls/harbor.crt" "${TMP_CERT}" 2>/dev/null; then
        log_info "已從 LXD 容器 ${MGMT_CONTAINER} 取得最新憑證"
    else
        log_info "透過 openssl 從 Harbor 連線取得憑證..."
        openssl s_client -showcerts -connect "${HARBOR_HOST}" -servername "${HARBOR_HOST%:*}" </dev/null 2>/dev/null | openssl x509 -outform PEM > "${TMP_CERT}" || \
            log_error "無法取得 Harbor 憑證，請確認 Harbor 是否正常運行"
    fi

    log_info "更新 Docker 與系統信任庫 (需要 sudo 權限)..."
    sudo mkdir -p "${CERTS_DIR}"
    sudo cp "${TMP_CERT}" "${CERTS_DIR}/ca.crt"
    sudo cp "${TMP_CERT}" /usr/local/share/ca-certificates/harbor.local.crt
    rm -f "${TMP_CERT}"

    sudo update-ca-certificates --fresh >/dev/null
    sudo systemctl restart docker
    sleep 2
    log_success "Harbor 憑證已更新並已重啟 Docker 守護行程"
fi

# ==========================================
# 3. Docker Login
# ==========================================
log_info "============================================"
log_info "步驟 3: 登入 Harbor"
log_info "============================================"
echo "${HARBOR_ADMIN_PASSWORD}" | docker login "${HARBOR_HOST}" -u "${HARBOR_ADMIN_USER}" --password-stdin \
    || log_error "登入 Harbor 失敗，請確認帳密是否正確 (HARBOR_ADMIN_USER/HARBOR_ADMIN_PASSWORD)"
log_success "已成功登入 Harbor (${HARBOR_HOST})"

# ==========================================
# 4. 確認 Harbor Project 存在
# ==========================================
log_info "============================================"
log_info "步驟 4: 確認 Harbor Project「${HARBOR_PROJECT}」存在"
log_info "============================================"

# 注意：Harbor API 在「找不到」時回 HTTP 200 + 空陣列 []，而非 404
# 因此必須檢查回應 body 是否真的包含該 project (欄位為 name)
PROJECT_QUERY=$(curl -s -k -u "${HARBOR_ADMIN_USER}:${HARBOR_ADMIN_PASSWORD}" \
    "https://${HARBOR_HOST}/api/v2.0/projects?name=${HARBOR_PROJECT}" 2>/dev/null || echo "")

if echo "${PROJECT_QUERY}" | grep -q "\"name\":\"${HARBOR_PROJECT}\""; then
    log_success "Project「${HARBOR_PROJECT}」已存在"
else
    log_info "Project「${HARBOR_PROJECT}」不存在，嘗試建立..."
    CREATE_RESULT=$(curl -s -k -u "${HARBOR_ADMIN_USER}:${HARBOR_ADMIN_PASSWORD}" \
        -X POST "https://${HARBOR_HOST}/api/v2.0/projects" \
        -H "Content-Type: application/json" \
        -d "{\"project_name\": \"${HARBOR_PROJECT}\", \"metadata\": {\"public\": \"true\"}}" \
        -w "\n%{http_code}" 2>/dev/null)

    CREATE_HTTP_CODE=$(echo "${CREATE_RESULT}" | tail -1)

    if [ "${CREATE_HTTP_CODE}" = "201" ] || [ "${CREATE_HTTP_CODE}" = "409" ]; then
        log_success "Project「${HARBOR_PROJECT}」建立成功 (HTTP ${CREATE_HTTP_CODE})"
    else
        log_error "Project 建立失敗 (HTTP ${CREATE_HTTP_CODE})，請確認 Harbor 帳密是否正確"
    fi
fi

# ==========================================
# 5. Tag + Push
# ==========================================
log_info "============================================"
log_info "步驟 5: 推送映像至 Harbor (${HARBOR_PROJECT}/${MINDSHUB_NAMESPACE}/...)"
log_info "============================================"

PUSHED_COUNT=0
for entry in "${IMAGE_LIST[@]}"; do
    IFS='|' read -r tar_file original_image <<< "$entry"

    # 本機不存在則跳過 (載入失敗或無 tar)
    if ! docker image inspect "${original_image}" &>/dev/null; then
        log_warn "跳過：${original_image}（本機不存在且載入未成功）"
        continue
    fi

    # 由 original_image 拆解 repo/tag (例: node:22-slim -> repo=node, tag=22-slim)
    img_repo="${original_image%:*}"
    img_tag="${original_image##*:}"
    harbor_target="${HARBOR_HOST}/${HARBOR_PROJECT}/${MINDSHUB_NAMESPACE}/${img_repo}:${img_tag}"

    log_info "--------------------------------------------"
    log_info "推送：${original_image} -> ${harbor_target}"

    # 建立/更新 Harbor tag
    docker tag "${original_image}" "${harbor_target}"

    # 推送
    docker push "${harbor_target}"
    log_success "推送完成：${harbor_target}"
    PUSHED_COUNT=$((PUSHED_COUNT+1))
done

if [ "$PUSHED_COUNT" -eq 0 ]; then
    log_error "沒有成功推送任何映像，請確認 image 是否載入成功"
fi

# ==========================================
# 6. 驗證上傳結果
# ==========================================
log_info "============================================"
log_info "步驟 6: 驗證 Harbor 上傳結果"
log_info "============================================"

VERIFY_OK=0
VERIFY_FAIL=0
for entry in "${IMAGE_LIST[@]}"; do
    IFS='|' read -r tar_file original_image <<< "$entry"

    # 跳過本機不存在的映像 (未推送)
    if ! docker image inspect "${original_image}" &>/dev/null; then
        continue
    fi

    img_repo="${original_image%:*}"
    img_tag="${original_image##*:}"
    harbor_target="${HARBOR_HOST}/${HARBOR_PROJECT}/${MINDSHUB_NAMESPACE}/${img_repo}:${img_tag}"

    log_info "驗證 repository ${HARBOR_PROJECT}/${MINDSHUB_NAMESPACE}/${img_repo} ..."
    # 用 artifacts 端點確認該 repository 是否有 tag (此端點穩定可靠)
    ARTIFACT_INFO=$(curl -s -k -u "${HARBOR_ADMIN_USER}:${HARBOR_ADMIN_PASSWORD}" \
        "https://${HARBOR_HOST}/api/v2.0/projects/${HARBOR_PROJECT}/artifacts?page_size=100" 2>/dev/null || echo "")

    if ! echo "${ARTIFACT_INFO}" | grep -q "\"repository_name\":\"${HARBOR_PROJECT}/${MINDSHUB_NAMESPACE}/${img_repo}\""; then
        log_warn "找不到 repository ${HARBOR_PROJECT}/${MINDSHUB_NAMESPACE}/${img_repo}"
        VERIFY_FAIL=$((VERIFY_FAIL+1))
        continue
    fi

    log_success "repository 存在：${HARBOR_PROJECT}/${MINDSHUB_NAMESPACE}/${img_repo}"

    # docker pull 回拉驗證
    docker pull "${harbor_target}" >/dev/null 2>&1 \
        && log_success "docker pull 驗證成功：${harbor_target}" \
        || log_warn "docker pull 驗證失敗：${harbor_target}"

    VERIFY_OK=$((VERIFY_OK+1))
done

# ==========================================
# 7. 完成
# ==========================================
echo ""
log_info "============================================"
log_info "推送完成"
log_info "============================================"
log_info "Harbor Project：${HARBOR_PROJECT}"
log_info "成功推送：${PUSHED_COUNT} 個映像"
log_info "驗證通過：${VERIFY_OK} 個"
[ "$VERIFY_FAIL" -gt 0 ] && log_warn "驗證失敗：${VERIFY_FAIL} 個"
log_info "Harbor Web UI：https://${HARBOR_HOST}"
echo ""
log_info "映像位置："
for entry in "${IMAGE_LIST[@]}"; do
    IFS='|' read -r tar_file original_image <<< "$entry"
    img_repo="${original_image%:*}"
    img_tag="${original_image##*:}"
    log_info "  ${HARBOR_HOST}/${HARBOR_PROJECT}/${MINDSHUB_NAMESPACE}/${img_repo}:${img_tag}"
done
echo ""
log_success "所有流程完成！"
