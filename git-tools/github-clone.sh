#!/usr/bin/env sh

set -e

if [ -z "$GITHUB_REPO" ]; then
    echo "GITHUB_REPO is required"
    exit 1
fi

LOCAL_REPO_PATH="${LOCAL_REPO_PATH:-code}"
if [ ! -d "$LOCAL_REPO_PATH/.git" ]; then
    REPO_URL="https://github.com/$GITHUB_REPO.git"
    if [ -n "$GITHUB_REF" ]; then
        git clone --branch "$GITHUB_REF" --recurse-submodules "$REPO_URL" "$LOCAL_REPO_PATH"
    else
        git clone --recurse-submodules "$REPO_URL" "$LOCAL_REPO_PATH"
    fi
fi
if [ -n "$GITHUB_SHA" ]; then
    cd "$LOCAL_REPO_PATH"
    git reset --hard "$GITHUB_SHA"
    git submodule update --init --recursive
    cd -
fi

LOCAL_REPO_OWNER="${LOCAL_REPO_OWNER:-1000:1000}"
chown -R "$LOCAL_REPO_OWNER" "$LOCAL_REPO_PATH"
