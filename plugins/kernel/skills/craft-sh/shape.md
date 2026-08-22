# Shape

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

