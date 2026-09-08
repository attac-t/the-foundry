# Oracles

## The tool lied

`herd services:start MySQL` prints `ERROR Unable to start service`. The port answers a second later.

```bash
wait_for() {
    local seconds="$1"
    shift
    for _ in $(seq 1 "$seconds"); do
        "$@" >/dev/null 2>&1 && return 0
        sleep 1
    done
    return 1
}

start_mysql() {
    herd services:start MySQL >/dev/null 2>&1     # its output is worthless
    wait_for 30 mysql_answers || fail "MySQL will not start" 2
}
```

## A missing value spins forever

`shift 2` with one argument left fails and leaves `$#` alone, so the loop never ends.

```bash
--name) [ $# -ge 2 ] || fail "--name needs a value" 1 ; NAME="$2" ; shift 2 ;;
```


## The pipe answered instead

`$?` after a pipeline is the last stage's. A `head` added to shorten the output answers 0 whatever
ran before it.

```bash
sh check.sh | head -4 ; echo "$?"        # head's status. Always 0
sh check.sh >/dev/null 2>&1 ; echo "$?"  # the check's
```

**Four wrong readings in one day came from this.** One nearly became a public finding.

A piped 0 was read against a second tool's honest 1 and written up as two tools disagreeing.
**They agreed.**

**The tell is that the pipe was added for readability.** Nothing about the command changed, so the
status looks like the command's.
