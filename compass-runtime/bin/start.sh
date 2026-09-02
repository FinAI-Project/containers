#!/usr/bin/env bash
# https://github.com/runpod/containers/blob/main/container-template/start.sh

set -e

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                #
# ---------------------------------------------------------------------------- #

# Execute script if exists
execute_script() {
    local script_path=$1
    local script_msg=$2
    if [ -f ${script_path} ]; then
        echo "${script_msg}"
        bash "${script_path}"
    fi
}

stop_runpod() {
    echo "Terminating RunPod pod: ${RUNPOD_POD_ID}"
    curl -fsS --max-time 30 --request DELETE \
        --header "Authorization: Bearer ${RUNPOD_API_KEY}" \
        --url "https://api.runpod.io/v2/pods/${RUNPOD_POD_ID}" \
        || echo "WARNING: Failed to terminate pod via API"
    sleep 5
}

# ---------------------------------------------------------------------------- #
#                               Main Program                                   #
# ---------------------------------------------------------------------------- #

if [ -n "${RUNPOD_POD_ID:-}" ] && [ -n "${RUNPOD_API_KEY:-}" ]; then
    trap stop_runpod EXIT
fi

if [ -z "${JOB_CMD:-}" ]; then
    echo "ERROR: JOB_CMD is not set" >&2
    exit 1
fi

echo "Pod Started"

execute_script "/app/bin/github-clone.sh" "Cloning GitHub repo..."

execute_script "/app/bin/pre-run.sh" "Running pre-run setup..."

if [ -f /tmp/runner/cuda.env ]; then
    source /tmp/runner/cuda.env
fi

# Run your application
set +e
JOB_START_TIME=$(date -u +%s)
/app/bin/entrypoint.sh bash -c "${JOB_CMD}"
JOB_EXIT_CODE=$?
set -e

export JOB_START_TIME JOB_EXIT_CODE
execute_script "/app/bin/post-run.sh" "Running post-run cleanup..."

exit "$JOB_EXIT_CODE"