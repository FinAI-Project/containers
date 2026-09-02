#!/usr/bin/env bash

if [ "$#" -eq 0 ]; then
    echo "No command provided" >&2
    exit 1
fi

if [ -z "${OUTPUT_DIR:-}" ]; then
    echo "OUTPUT_DIR is not set" >&2
    exit 2
fi

set -euo pipefail

CHILD_PID=""
OUTPUT_TAR="${OUTPUT_DIR%/}.tar.gz"
OUTPUT_TMP="${OUTPUT_TAR}.tmp"

_output_handler() {
    local output_path="$1"

    find . -type d -name .cache -prune -exec rm -rf {} +
    if [ "${CLOUD_PLATFORM}" == "azure" ]; then
        mkdir -p "$OUTPUT_DIR"
        rsync -rltv --exclude=".*" --exclude "core*" --exclude='mlruns' ./ "$OUTPUT_DIR"/
    else
        tmp_file=$(mktemp)
        tar --exclude='mlruns' -zcvf "$tmp_file" .
        mkdir -p $(dirname "$output_path")
        cp "$tmp_file" "$output_path"
        rm -f "$tmp_file"
    fi
}

_term_handler() {
    trap - TERM INT
    echo "Received termination signal, killing child process: ${CHILD_PID}" >&2
    if [ -n "${CHILD_PID}" ] && kill -0 "${CHILD_PID}" 2>/dev/null; then
        kill -TERM "${CHILD_PID}" 2>/dev/null || true
        wait "${CHILD_PID}" 2>/dev/null || true
    fi
    _output_handler "$OUTPUT_TMP"
    exit 143
}

mkdir -p /tmp/runner
cd /tmp/runner

trap _term_handler TERM INT

if [ -n "$OUTPUT_DIR" ]; then
    if [ -f "$OUTPUT_TMP" ]; then
        tar -zxvf "$OUTPUT_TMP" -C .
    elif [ -d "$OUTPUT_DIR" ]; then
        cp -a "$OUTPUT_DIR"/. .
    fi
    if [ -f "done" ]; then
        rm done
    fi
fi

set +e
"$@" &
CHILD_PID=$!
wait "$CHILD_PID"
EXIT_CODE=$?
set -e

trap - TERM INT

printf '%s' "$EXIT_CODE" > done

_output_handler "$OUTPUT_TAR"
rm -f "$OUTPUT_TMP"

exit "$EXIT_CODE"