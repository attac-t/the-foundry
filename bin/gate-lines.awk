#
# Each gate line in `bin/gates.sh` that floor can pin, as `name interpreter path arguments`.
#
# A gate line is `gate <name> sh <path>` or `bash <path>`, wherever it sits, so a guarded one is
# read too. Its path must be literal by the rule floor's own reader keeps, or floor cannot pin it.
#
# `bin/agree.sh` and `tests/gates.sh` both read through this file, so the two cannot part. #1172.
{
    for (i = 1; i + 3 <= NF; i++) {
        if ($i != "gate") continue
        if ($(i + 2) != "sh" && $(i + 2) != "bash") continue
        if ($(i + 3) !~ /^[A-Za-z0-9_.\/-]+$/) continue

        line = $(i + 1) " " $(i + 2) " " $(i + 3)
        for (j = i + 4; j <= NF; j++) line = line " " $j
        print line
    }
}
