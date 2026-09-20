#!/bin/sh
# PostToolUse: keep the claim this run holds, so a second host cannot take work still being done.
#
# **A claim is broken on age, and until now nothing renewed it.** `take_claim`
# re-stamps for its own holder in both adapters. What was missing was a caller
# on a path a working host repeats, and an edit is that path.
#
# **The runner decides whether it is due, not this file.** A hook that carried
# the window would be a second copy of it, and two copies drift.
#
# **An edit was not the whole of that path.** A host waiting on a grade makes
# no edit at all, and one detached audit here ran forty-eight minutes — inside
# twenty per cent of the hour a claim is broken after. Measured 20 September.
#
# **So any tool use counts.** Reading a log is a host still on the work, and a
# claim exists to say somebody is. The runner throttles on a local mark, so the
# extra fires cost a `stat` rather than a read across the network.
#
# Silent and exit 0 whatever happens. A command must never report a failure
# because a claim could not be kept — #859 names that as its own risk.

root="$(cd "$(dirname "$0")/.." && pwd)"

sh "$root/bin/run.sh" claim >/dev/null 2>&1

exit 0
