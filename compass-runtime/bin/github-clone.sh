#!/usr/bin/env bash

set -eu

LOCAL_REPO_PATH="${LOCAL_REPO_PATH:-code}"
if [ -d "${LOCAL_REPO_PATH}/.git" ]; then
    echo "INFO: Repository already exists at ${LOCAL_REPO_PATH}, skipping clone (local dev mode)"
    echo "INFO: Using existing checkout, ignoring GITHUB_REF and GITHUB_SHA"
    exit 0
fi

if [ -z "${GITHUB_REPO:-}" ]; then
    echo "[git] ERROR: GITHUB_REPO is required (e.g. owner/repo)" >&2
    exit 1
fi

REPO_URL="https://github.com/${GITHUB_REPO}.git"

echo "[git] Cloning repository: ${GITHUB_REPO}"

mkdir -p "${LOCAL_REPO_PATH}"

# Case 1: Specific SHA requested → fetch with enough depth to reach it
if [ -n "${GITHUB_SHA:-}" ]; then
    echo "[git] Fetching specific SHA: ${GITHUB_SHA}"
    git clone --no-checkout "${REPO_URL}" "${LOCAL_REPO_PATH}"
    cd "${LOCAL_REPO_PATH}"
    git fetch --depth 1 origin "${GITHUB_SHA}"
    git checkout -q "${GITHUB_SHA}"
    git submodule update --init --recursive
    cd -

# Case 2: Specific REF (branch/tag) requested → shallow clone of that ref
elif [ -n "${GITHUB_REF:-}" ]; then
    echo "[git] Shallow cloning branch/tag: ${GITHUB_REF} (depth 1)"
    git clone --depth 1 --branch "${GITHUB_REF}" --recurse-submodules "${REPO_URL}" "${LOCAL_REPO_PATH}"

# Case 3: No ref, no sha → shallow clone of default branch
else
    echo "[git] Shallow cloning default branch (depth 1)"
    git clone --depth 1 --recurse-submodules "${REPO_URL}" "${LOCAL_REPO_PATH}"
fi

echo "[git] Repository cloned successfully to ${LOCAL_REPO_PATH}"