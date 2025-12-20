#!/usr/bin/env bash

START_TIME=$(date "+%b %d %H:%M:%S %z")
WORK_DIR="/tmp/runner"

set -e
mkdir -p "$OUTPUT_DIR"
set +e

while [ ! -f "$WORK_DIR/done" ]; do
    minute=$(date +'%-M')
    if [ $((minute % 10)) -eq 0 ]; then
        rsync -rlt --exclude=".*" --exclude "core.*" "$WORK_DIR/" "$OUTPUT_DIR"
    fi
    sleep 60
done

rsync -rltv --delete --exclude "core.*" "$WORK_DIR/" "$OUTPUT_DIR"
if [ -n "$WEBHOOK_URL" ]; then
    END_TIME=$(date "+%b %d %H:%M:%S %z")
    EXIT_CODE=$(cat "$WORK_DIR/done")
    if [ -n "$EXIT_CODE" ] && [ "$EXIT_CODE" -eq 0 ]; then
        JOB_STATUS_TEXT="completed"
        JOB_STATUS_EMOJI="✅"
    else
        JOB_STATUS_TEXT="failed to complete"
        JOB_STATUS_EMOJI="❌"
    fi
    curl -v -X POST -H 'Content-type: application/json' --data '{"blocks":[{"type":"section","text":{"type":"mrkdwn","text":"'"$JOB_STATUS_EMOJI"' '"$POD_NAME"' '"$JOB_STATUS_TEXT"'"}},{"type":"section","fields":[{"type":"mrkdwn","text":"*Experiment Batch:*\n'"$EXP_BATCH"'"},{"type":"mrkdwn","text":"*Experiment Name:*\n'"$EXP_NAME"'"},{"type":"mrkdwn","text":"*Started:*\n'"$START_TIME"'"},{"type":"mrkdwn","text":"*Completed:*\n'"$END_TIME"'"},{"type":"mrkdwn","text":"*Actor:*\n'"$EXP_ACTOR"'"}]}]}' "$WEBHOOK_URL"
fi
