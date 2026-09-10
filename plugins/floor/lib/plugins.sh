#!/bin/sh
#
# What this host has, against what its marketplaces ship.
#
# **The marketplace says what a plugin ships, never the working tree.** Reading the tree answered
# only where the tree was Foundry. A repository that installs Foundry has no `plugins/` directory,
# so the loop found nothing and the count said zero — the host #559 calls the harder case, told the
# least.
#
# The harness records where each marketplace lives. A directory source points at the checkout
# itself; a github source points at its own clone. **Both hold the plugin manifests**, so one read
# answers for a maintainer and a consumer alike.
#
# Two questions, and naming them the same would make one of them wrong:
#
#     host      what has this host got, everywhere it registered anything
#     session   what could a session standing in one repository load
#
# **`session` is the quiet one.** Ninety-six rows on the machine this was written on point at
# directories deleted weeks ago, and `host` reports them because they are there. None can reach a
# session, so `session` says nothing about them.
#
# Usage: sh plugins.sh host
#        sh plugins.sh session <repository>
#
# Exit: 0 answered, 2 asked for something this does not do
#
set -u

# Everything this host registered, everywhere. Silent per plugin when the versions agree, because a
# line each would bury the one that drifted — and drift is the only thing a person acts on.
report_plugins_this_host_registered() {
    seen=0

    markets=$(marketplaces_this_host_registered_from)
    [ -n "$markets" ] || { say_nothing_was_installed; return; }

    for market in $markets; do
        where=$(marketplace_location "$market")
        [ -n "$where" ] || { say_a_marketplace_with_no_home "$market"; continue; }

        for named in $(plugins_offered_by "$where"); do
            seen=$((seen + 1))
            say_a_plugin_that_drifted "$where" "$named"
        done
    done

    say "plugin  $seen offered here, checked against what this host registered"
}

# **Nothing to check is not a clean check**, and every other absence on this path names its file.
# A count of zero read the same as a count of zero wrong, which is the fault `bin/gates.sh` refuses
# for every gate in this repository.
say_nothing_was_installed() {
    say "plugin  none. Nothing was installed here through a marketplace"
    say "        plugins/installed_plugins.json under CLAUDE_CONFIG_DIR, or ~/.claude, is where that is kept"
}

# The other half of the same silence. A key names a marketplace the harness has no home for, so the
# plugins behind it cannot be read and skipping said so to nobody.
say_a_marketplace_with_no_home() {
    say "        $1 — this host registered from it, and nothing says where it lives"
}

# The marketplaces this host actually took something from, never every one it knows. A key joins
# the two names and is the only place they are joined.
marketplaces_this_host_registered_from() {
    record=$(host_record) || return 0

    awk -F'"' '/^    "/ && index($2, "@") { print substr($2, index($2, "@") + 1) }' "$record" \
        | sort -u
}

#
# Where the harness put it. **The path is JSON-escaped, and the count is not what it looks like** —
# four backslashes in the pattern match the two the file holds, and two in the replacement write one.
#
# **Eight was written first and matched nothing.** It left the path doubled, which Windows opens
# anyway because it tolerates a repeated separator — so the mistake ran green for a day. The same
# eight, folding to `/` instead, is what caught it: a doubled path never equals an undoubled one.
#
# Measured 9 September on gawk, against the real record.
marketplace_location() {
    known="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/known_marketplaces.json"

    [ -r "$known" ] || return 1

    awk -F'"' -v want="$1" '
        /^  "/ && $2 == want       { hit = 1; next }
        hit && /^  "/              { hit = 0 }
        hit && /"installLocation"/ { p = $4; gsub(/\\\\/, "\\", p); print p; exit }
    ' "$known"
}

# What that marketplace offers, from its own manifest. A layout guessed instead breaks on the first
# marketplace keeping its plugins elsewhere, and one on the host this was written on has no
# `plugins/` directory at all.
plugins_offered_by() {
    manifest="$1/.claude-plugin/marketplace.json"

    [ -r "$manifest" ] || return 0

    awk -F'"' '/^      "name"/ { print $4 }' "$manifest"
}

# Where one plugin sits inside it, relative to the marketplace's own root.
source_of_plugin() {
    manifest="$1/.claude-plugin/marketplace.json"

    awk -F'"' -v want="$2" '
        /^      "name"/            { mine = ($4 == want) }
        mine && /^      "source"/  { print $4; exit }
    ' "$manifest"
}

# Absent and behind are different remedies. One is an install, the
# the other one is an update, and a host that is told only that
# something is wrong goes off looking for the wrong command.
say_a_plugin_that_drifted() {
    where=$1
    named=$2

    at=$(source_of_plugin "$where" "$named")
    [ -n "$at" ] || return 0

    ships=$(version_in "$where/$at/.claude-plugin/plugin.json")
    every=$(every_version_registered_for "$named")
    here=$(printf '%s\n' "$every" | sort -u | paste -sd, -)

    [ "$here" = "$ships" ] && return
    [ -n "$here" ] || { say "        $named $ships is NOT installed here"; return; }

    say "        $named ships $ships, and this host has $here registered$(places_if_it_repeats "$every")"
}

# **Registered, never loaded.** A row in that file records an install, and nothing there says a
# session read it. Fifty of kernel's fifty-two named `.claude/worktrees/` directories deleted weeks
# earlier, and calling those loaded said five copies were running when one was.
#
# Dropping them is what this deliberately does not do, and the reason has narrowed to one.
#
# **The escaping was never the obstacle.** `marketplace_location` halves the same path, and its
# comment carries the counts. What stands is that a path written by another operating system cannot
# be tested here at all, so a row this shell cannot resolve reads as deleted — and dropping it would
# hide a real drift, which is the worse failure of the two.
#
# So say how many places instead, and only when it repeats. One install per version is the
# ordinary case and the count adds nothing to it.
places_if_it_repeats() {
    installs=$(printf '%s\n' "$1" | grep -c .)
    versions=$(printf '%s\n' "$1" | sort -u | grep -c .)

    [ "$installs" -gt "$versions" ] || return 0

    printf ' in %s places' "$installs"
}

# The value after the key, never the fourth field. A manifest with two
# keys on one line is legal, and counting the fields reads back the
# very first value it meets, and that was the plugin's own name.
version_in() {
    awk -F'"' '{ for (i = 1; i < NF; i++) if ($i == "version") { print $(i + 2); exit } }' "$1"
}

# The record a harness keeps of what it installed. Read by name and never
# by path: a cache directory name is one harness's own layout, and the
# next one will be keeping that very same fact somewhere else, too.
# Every version, not the first.
#
# A plugin's key holds a **list** of installs — one for user scope and one for every project that
# ever registered it. Measured on this host: kernel 52, signal 48, five and six versions between
# them, and floor's two disagreeing on the day one of them was updated.
#
# The `exit` here read the first and stopped, so a host running five kernels reported one and looked
# clean. **A check that answers about a name must ask whether the name repeats.**
#
# The boundary is the next key at four spaces. Nothing inside an install is indented that shallowly.
#
# One line per install, undeduplicated, because the caller needs both the set and the count.
every_version_registered_for() {
    record=$(host_record) || return 0

    awk -F'"' -v want="$1" '
        index($0, "\"" want "@") { hit = 1; next }
        hit && /^    "/           { hit = 0 }
        hit && /"version"/        { print $4 }
    ' "$record"
}

# What the harness wrote down about its own installs. Named once, because two readers used to build
# the same path and only one of them would have moved.
host_record() {
    said="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json"

    [ -r "$said" ] || return 1

    printf '%s' "$said"
}

# --- what a session could load ---

#
# A row reaches a session when nobody scoped it to a project, or when the project is the one the
# session stands in. **Everything else belongs to another directory and cannot arrive here.**
#
# Measured 9 September 2026: kernel's fifty-two rows become two, signal's forty-eight become two,
# and one line is left — a plugin registered at two versions for the same checkout.
#
# A string, never a filesystem test. `[ -d ]` cannot answer for a path written by another operating
# system, and such a path is simply not this repository — which is the whole question here.
# **The two absences speak, in `host`'s own words.** A session that hears nothing has to know the
# check ran, and until 10 September an unreadable record and a healthy host gave the same empty
# output. An adversary found it. The header above had said so for a week.
#
# **A plugin offered and never installed is not one of them.** That is an answer, not a failed read.
# Eight of those a session is the noise this design refuses, and `host` already says it to the
# person who asked.
report_what_this_session_could_load() {
    markets=$(marketplaces_this_host_registered_from)
    [ -n "$markets" ] || { say_nothing_was_installed; return; }

    for market in $markets; do
        where=$(marketplace_location "$market")
        [ -n "$where" ] || { say_a_marketplace_with_no_home "$market"; continue; }

        for named in $(plugins_offered_by "$where"); do
            say_a_plugin_this_session_could_load "$where" "$named" "$1"
        done
    done
}

# Silent when the reachable versions are the one the marketplace ships. A hook that speaks on a
# healthy host is a hook nobody reads by the end of the week.
say_a_plugin_this_session_could_load() {
    at=$(source_of_plugin "$1" "$2")
    [ -n "$at" ] || return 0

    ships=$(version_in "$1/$at/.claude-plugin/plugin.json")
    here=$(versions_reachable_from "$2" "$3")

    [ -z "$here" ] && return 0
    [ "$here" = "$ships" ] && return 0

    say "plugin  $2 ships $ships, and this session could load $here"
}

# The versions on rows a session can reach. `scope` is read before `version` in every record the
# harness writes, and `projectPath` sits between them when there is one.
versions_reachable_from() {
    record=$(host_record) || return 0
    here=$(printf '%s' "$2" | tr 'A-Z\\' 'a-z/')
    awk -F'"' -v want="$1" -v here="$here" '
        index($0, "\"" want "@") { hit = 1; next }
        hit && /^    "/          { hit = 0 }
        !hit                     { next }

        /"scope"/       { mine = ($4 != "project") }
        /"projectPath"/ { p = tolower($4); gsub(/\\\\/, "/", p); mine = (p == here) }
        /"version"/     { if (mine) print $4 }
    ' "$record" | sort -u | paste -sd, -
}

say() { printf '%s
' "$1"; }

case "${1:-}" in
    host)    report_plugins_this_host_registered ;;
    session) shift; report_what_this_session_could_load "${1:-}" ;;
    *)       echo "plugins: host | session <repository>" >&2
             exit 2 ;;
esac
