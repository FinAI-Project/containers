#!/usr/bin/env bash

if [ -n "$EXTRA_INIT_SCRIPT" ] && [ -f "$EXTRA_INIT_SCRIPT" ]; then
    . "$EXTRA_INIT_SCRIPT"
fi

if [ -n "$GITHUB_REPO" ]; then
    TOKEN=$(python get-token.py) || {
        echo "get token failed: $TOKEN"
        exit 1
    }

    set -e
    REPO_URL="https://x-access-token:$TOKEN@github.com/$GITHUB_REPO.git"
    if [ -n "$GITHUB_REF" ]; then
        git clone --branch "$GITHUB_REF" --recurse-submodules "$REPO_URL"
    else
        git clone --recurse-submodules "$REPO_URL"
        if [ -n "$GITHUB_SHA" ]; then
            cd $(basename "$GITHUB_REPO")
            git reset --hard "$GITHUB_SHA"
        fi
    fi
    set +e
fi

mkdir -p /tmp/runner
cd /tmp/runner
if [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ]; then
    cp -rpv "$OUTPUT_DIR/"* .
fi
if [ -f "done" ]; then
    rm done
fi
"$@"
EXIT_CODE=$?
echo -n $EXIT_CODE > /tmp/runner/done

if [ -n "$WORK_DIR" ] && [[ "$WORK_DIR" == /output/* ]]; then
    mkdir -p "$WORK_DIR"
    cp -R --preserve=timestamps . "$WORK_DIR"
fi

exit $EXIT_CODE