#!/usr/bin/env bash

set -euo pipefail

DATA_DIR="${DATA_DIR:-${DATA_SOURCE_PATH:-}}"

if [ -z "${DATA_DIR:-}" ]; then
    echo "ERROR: DATA_DIR is not set" >&2
    exit 1
fi

case "${DATA_DIR}" in
    /data/*) ;;
    *)
        echo "ERROR: DATA_DIR must be under /data/ (got: ${DATA_DIR})" >&2
        exit 1
        ;;
esac

dataset_name="${DATA_DIR#/data/}"

case "${dataset_name}" in
    ""|*".."*|/*)
        echo "ERROR: invalid DATA_DIR: ${DATA_DIR}" >&2
        exit 1
        ;;
esac

echo "[pre-run][1/3] Generating CUDA environment..."
mkdir -p /tmp/runner
python /app/bin/gen-cuda-env.py /tmp/runner/cuda.env

tarfile="${dataset_name}.tar.gz"
local_tar="${DATA_CACHE_DIR:-/tmp}/${tarfile}"
data_parent="$(dirname "${DATA_DIR}")"

if [ -d "${DATA_DIR}" ] && [ -n "$(ls -A "${DATA_DIR}" 2>/dev/null)" ]; then
    echo "[pre-run] Data already exists at ${DATA_DIR}, skipping download and extract."
    exit 0
fi

echo "[pre-run][2/3] Syncing ${tarfile}..."
mkdir -p "$(dirname "${local_tar}")"
rclone copyto ":azureblob:model-data/${tarfile}" "${local_tar}" -v --checksum

echo "[pre-run][3/3] Extracting to ${data_parent}..."
mkdir -p "${data_parent}"
tar -xzf "${local_tar}" -C "${data_parent}"

# Verify extraction produced files
if [ ! -d "${DATA_DIR}" ] || [ -z "$(ls -A "${DATA_DIR}" 2>/dev/null)" ]; then
    echo "ERROR: Extraction completed but ${DATA_DIR} is empty or missing" >&2
    exit 1
fi

echo "[pre-run] Data ready at ${DATA_DIR}"