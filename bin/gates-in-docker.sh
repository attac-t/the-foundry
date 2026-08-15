#!/bin/sh
#
# Run the gates on Linux, where `sh` is dash.
#
# Copied in, not mounted: the suites write, and a bind mount leaves their work in your checkout.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)

# Git Bash says `/c/Users/...`, which Docker on Windows cannot read, and rewrites `/src` into a
# Windows path on the way to the container. `cygpath -m` gives the first one `C:/Users/...`, and
# MSYS_NO_PATHCONV stops the second. Both are no-ops anywhere else.
if command -v cygpath >/dev/null 2>&1; then
    root=$(cygpath -m "$root")
    MSYS_NO_PATHCONV=1
    export MSYS_NO_PATHCONV
fi

docker build -q -t foundry-gates -f "$root/bin/gates.Dockerfile" "$root" >/dev/null

# `safe.directory` because the copy is owned by whoever built the image, and git refuses a
# repository it thinks belongs to someone else.
docker run --rm -v "$root:/src:ro" foundry-gates sh -c '
    cp -r /src ~/repo
    cd ~/repo
    git config --global --add safe.directory ~/repo
    sh bin/gates.sh
'
