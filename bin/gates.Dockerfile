# Debian because its `/bin/sh` is dash. On macOS and Git Bash `sh` *is* bash and takes `&>` and
# `[[ =~ ]]` without a word, so neither can fail a bashism — and every runner here opens `#!/bin/sh`.
#
# Built by `bin/gates.sh linux`.

# **Pinned by digest, so two machines build the same image.** `stable-slim` moves, and a host that
# grades a week after another would grade against a different `dash`, `mawk` and `git`.
#
# To move it on purpose: `docker pull debian:stable-slim`, then
# `docker image inspect debian:stable-slim --format '{{index .RepoDigests 0}}'`, and paste it here.
#
# **The packages below are not pinned and cannot be.** Debian's archive drops old versions within
# weeks, so a pinned version is a build that breaks rather than a build that repeats. The digest
# holds the base; `apt-get` still floats, and that is the limit.
FROM debian:stable-slim@sha256:1710bde34461551a19a47c787885ec9ad7058d9a5bead2affb8d088fa2f8502b

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
#
# `gh` — **no gate needs it and delivery cannot happen without it.** Floor's GitHub adapter answers
# only where `gh` is, so an image with none grades and stops. It is here from Debian's own archive,
# which is why this takes no key, no `curl` and no third-party source.
#
# **It is a binary, never a sign-in.** A token belongs to the host and arrives when the container
# starts, and nothing here reaches a network at run time.
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends git python3 gh ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Not root. Root ignores permission bits, so a gate that must refuse an unwritable directory would
# pass here and fail for every real user — floor has one, and it went untested until this existed.
RUN useradd --create-home --uid 1000 forge
USER forge
WORKDIR /home/forge

# **An empty mount point, never a home.** Docker gives a fresh named volume the ownership of whatever
# the image has at that path, and creates it owned by root when the image has nothing. `forge` then
# cannot write, and floor says so: `could not write /home/forge/.foundry/runs`.
#
# It holds nothing. What a run records arrives from the host, at run time.
RUN mkdir -p /home/forge/.foundry
