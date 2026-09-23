#!/bin/sh
#
# Install Foundry's plugins into this harness, once. `bin/host.sh` runs it inside a worker, where the
# harness keeps its config on the keys volume, so what it installs is there at every later start.
#
# **The harness's own lists are the oracle, never a marker file.** A plugin removed by hand would
# leave a marker saying it is there. A start that finds everything installed asks the network nothing.
#
# Usage: sh bin/install.sh <source> <marketplace> <plugin...>
#
# Exit: 0 everything named is installed, 1 an install failed, 2 usage

set -u

main() {
    [ "$#" -ge 3 ] || { say "usage: sh bin/install.sh <source> <marketplace> <plugin...>"; exit 2; }
    from=$1 market=$2
    shift 2

    ensure_the_marketplace_is_known
    have=$(claude plugin list --json 2>/dev/null)
    for plugin in "$@"; do ensure_installed "$plugin"; done
}

ensure_the_marketplace_is_known() {
    marketplace_is_known && return 0

    claude plugin marketplace add "$from" >/dev/null || fail "no marketplace could be added from $from"
    marketplace_is_known || fail "a marketplace was added from $from, and none is named $market"
    say "install: added $market, from $from"
}

ensure_installed() {
    plugin_is_installed "$1" && return 0

    claude plugin install "$1@$market" >/dev/null || fail "$1@$market could not be installed"
    say "install: installed $1@$market"
}

marketplace_is_known() { claude plugin marketplace list --json 2>/dev/null | grep -q "\"name\": *\"$market\""; }

# Read once, before the first install, so a start with three plugins asks the harness once.
plugin_is_installed() { printf '%s' "$have" | grep -q "\"$1@$market\""; }

say()  { printf '%s\n' "$1"; }
fail() { say "install: $1" >&2; exit 1; }

main "$@"
