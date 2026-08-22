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

