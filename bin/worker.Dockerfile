# The host, plus the two things that do the work. **Built on the grading image, never beside it.**
#
# `bin/gates.Dockerfile` stays 258 MB and the container grading lane keeps using it. Adding these
# there would make every grade carry 1.3 GB it never calls — measured 11 September 2026:
#
#     foundry-host            258 MB
#     plus nodejs and npm     457 MB
#     plus both providers     1.56 GB
#
# **`FROM foundry-host` is what keeps the promise the other file opens with.** Two independent
# recipes can disagree about what is installed. One built on the other cannot.
FROM foundry-host

USER root

# Debian's own archive, so this takes no key and no third-party source. `npm` is what both providers
# publish through, and it is the only runtime either needs.
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends nodejs npm \
 && rm -rf /var/lib/apt/lists/*

# **Pinned, for the reason the base is pinned.** A moving version undoes #694 on the next build, and
# two machines would judge through different software while reporting the same thing.
#
# To move one on purpose: change the number here and rebuild.
RUN npm install -g --no-fund --no-audit \
        @anthropic-ai/claude-code@2.1.268 \
        @openai/codex@0.154.0

# Not root, for the reason the base says: root ignores permission bits, so a check that must refuse
# an unwritable directory would pass here and fail for every real user.
USER forge
