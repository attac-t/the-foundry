# Craft Sh: Examples

From one script. It links a git worktree into a local web server, proves which checkout answered,
and puts it back.

---

## An `elif` chain becomes a predicate

```bash
# Before — the rule is smeared across the loop
if [ -n "$WANTED" ]; then
    [ "$domain" = "$WANTED" ] && { BEST="$domain"; BEST_ROWS=$rows; }
elif [ "$rows" -gt "$BEST_ROWS" ]; then
    BEST="$domain"; BEST_ROWS=$rows
fi

# After — the rule has a name
beats_current() {
    [ -n "$WANTED_TENANT" ] && { [ "$1" = "$WANTED_TENANT" ]; return; }
    [ "$2" -gt "$TENANT_PRODUCTS" ]
}

beats_current "$domain" "$products" || continue
TENANT="$domain" TENANT_PRODUCTS="$products"
```

## Guard, return, carry on

```bash
refuse_a_site_serving_another_path() {
    REGISTERED=$(site_row parked "$NAME"; site_row links "$NAME")

    [ -z "$REGISTERED" ] && return 0
    printf '%s' "$REGISTERED" | grep -qF "$ROOT" && return 0

    fail "$SITE already serves another path — pass --name" 1
}
```

## Ask, then repair

```bash
herd_is_listening() { nc -z 127.0.0.1 443; }
mysql_answers()     { query -e "SELECT 1"; }

ensure_herd_serves() {
    step "Herd"
    herd_is_listening || start_herd
    note "web server up"
}
```

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

## One voice

```bash
step() { printf '\n\033[1m▸ %s\033[0m\n' "$1"; }
note() { printf '  %s\n' "$1"; }
fail() { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit "$2"; }
```

---

## Traps

### `sed -i ''` is BSD-only

GNU `sed` reads `''` as the script. `awk` to a temp file also keeps key order.

```bash
write_env() {
    awk -v key="$1" -v value="$2" '
        $0 ~ "^" key "=" { print key "=" value; found = 1; next }
        { print }
        END { if (!found) print key "=" value }
    ' "$ROOT/.env" > "$ROOT/.env.$$" && mv "$ROOT/.env.$$" "$ROOT/.env"
}
```

### Dates sort as text

`date -j -f` is BSD-only.

```bash
[ "$expires" \< "$(date +%F)" ] || return 0
```

### A path may hold spaces

`awk '{print $1}'` cuts at the first space. Here that repoints the wrong checkout.

```bash
MAIN=$(git -C "$ROOT" worktree list --porcelain | awk 'NR == 1 { sub(/^worktree /, ""); print }')
```

### An absent key must not reach the tool

`mysql -P ""` fails: `Empty value for 'port' specified`. Put the default beside the key.

```bash
read_env() {                                     # read_env KEY [DEFAULT]
    local value
    value=$(grep -m1 "^$1=" "$ROOT/.env" 2>/dev/null | cut -d= -f2- | tr -d '"' | trim)
    printf '%s' "${value:-${2:-}}"
}

MYSQL=(mysql -h "$(read_env DB_HOST 127.0.0.1)" -P "$(read_env DB_PORT 3306)" -u "$(read_env DB_USERNAME root)")
```

## A Docbloc, Shaped

Both hold the same facts and only one is read.

```bash
#
# **A GitHub remote whose `gh` is missing is half of level 1.** The directory answers, correctly —
# `gh` is not in the dependency contract — but a directory has never heard of Issues, so its *nothing
# there* is the same words as an item that exists and cannot be reached.
#
# Said once, on stderr, and the exit code stays the adapter's.
#
remote_is_github && echo "source: the remote is GitHub and gh is not here" >&2
```

```bash
# A GitHub remote with no `gh` is answered by a directory, which never heard of
# Issues, so its nothing-there reads the same as an item nobody could
# reach. Said on stderr, and the exit code stays the adapter's.
remote_is_github && echo "source: the remote is GitHub and gh is not here" >&2
```

Four lines shorter for the same facts. What went: two fence lines the blank line above already drew,
a bold that shouted the sentence it sat in, and a paragraph that restated the first.

What arrived is the taper — **79, 69, 63**. The block narrows to a point, so the eye finds its end
without counting, and the third line is short enough that a fourth would look wrong. That is the
whole mechanism: the shape refuses the rambling before you write it.

**Nothing measures it.** Break where the sentence lets you. If a line will not shorten without losing
a fact, the fact stays and the block is two lines — a distinction lost to a shape is the failure
`economy` names, never the saving.
