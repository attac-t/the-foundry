# Voice

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

