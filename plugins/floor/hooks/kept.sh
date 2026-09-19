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
# **Every edit, and the source asked on few of them.** `renew_this_run_claim`
# returns before asking while the claim is young.
#
# Silent and exit 0 whatever happens. An edit must never report a failure
# because a claim could not be kept — #859 names that as its own risk.

root="$(cd "$(dirname "$0")/.." && pwd)"

sh "$root/bin/run.sh" claim >/dev/null 2>&1

exit 0
