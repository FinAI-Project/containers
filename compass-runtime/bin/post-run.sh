#!/usr/bin/env bash

set -eu

if [ "${CLOUD_PLATFORM}" != "azure" ]; then
    echo "[post-run] Uploading output to Azure Blob Storage..."
    rclone copy --checksum --max-age 24h --no-traverse --log-level INFO /output ":azureblob:model-output/" \
        || echo "[post-run] WARNING: rclone upload failed (exit $?)"
fi

echo "[post-run] Sending Slack notification..."
python /app/bin/slack-notifier.py --start-time="${JOB_START_TIME}" --exit-code="${JOB_EXIT_CODE}" \
    || echo "[post-run] WARNING: Slack notification failed (exit $?)"

if [ "${JOB_EXIT_CODE}" -eq 0 ]; then
    echo "[post-run] All done. Job completed successfully."
else
    echo "[post-run] All done. Job failed with exit code ${JOB_EXIT_CODE}."
fi