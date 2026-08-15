# The Linux runner the gates need, and nothing more.
#
# Debian for one reason: its `/bin/sh` is dash. On macOS and under Git Bash `sh` *is* bash and takes
# `&>`, `[[ =~ ]]` and `${BASH_SOURCE[0]}` without a word — so neither can fail a bashism, and every
# runner this repository ships opens `#!/bin/sh`.
#
# Build and run it with `bin/gates-in-docker.sh`.

FROM debian:stable-slim

# The base already has dash, bash, mawk, sed and grep. Two things are missing, and they are missing
# for different reasons.
#
# `git` — every suite needs it, and a plugin that ships code may declare it.
#
# `python3` — only `bin/frontmatter.sh` and `bin/versions.sh` need it, to parse frontmatter and JSON.
# Those are this repository's own tooling, not shipped plugin code, and CI's runner image happened to
# carry python so nothing ever said so out loud. **The four plugin suites pass without it**, which is
# this image's other use: it holds the `sh`, `awk`, `git` contract to its word, and would go red if a
# plugin ever reached past it.
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends git python3 ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Not root. Root ignores permission bits, so a gate that must refuse an unwritable directory would
# pass here and fail for every real user — floor has one, and it went untested until this existed.
RUN useradd --create-home --uid 1000 forge
USER forge
WORKDIR /home/forge
