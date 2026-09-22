---
name: host
description: Take a machine that has Docker to a Foundry host that answers. Covers the clone, the image, the sign-ins, installing the plugins, and the calls that prove it. Use when setting a machine up to run Foundry work. Not for joining a host to a repository, which is floor's join.sh.
---

# Host

> "Docker installed is not a host. A host is a machine something answers in."

## When

A person points at a machine and says *set this up to work on its own*.

Once per machine. Docker is the one thing it must already have.

## The path

### 1. Ask Docker

```sh
docker info
```

Anything but a clean answer stops every step below, and `bin/host.sh` refuses at exit 2 rather
than guessing.

### 2. Clone Foundry onto the machine

```sh
git clone https://github.com/attac-t/the-foundry.git
cd the-foundry
```

**The image carries no Foundry.** `bin/host.sh` is in this clone, and every container mounts the
clone at `/src`, read-only. **That mount is how the scripts get in. Step 6 is how the plugins do.**

### 3. Name a place for the sign-ins

`FOUNDRY_KEYS` names it, and the value's own shape picks the mechanism. A bare word is a Docker
volume. Anything holding a slash is a directory on this machine.

```sh
FOUNDRY_KEYS=foundry-keys
```

**Unset, nothing is kept.** Every sign-in below is then asked again in the next container, and that
is the default everywhere.

### 4. Start the host that can work

```sh
FOUNDRY_KEYS=foundry-keys sh bin/host.sh --worker
```

It builds, then opens a shell inside. Measured 11 September 2026: 258 MB for the host, 1.56 GB once
both harnesses sit on it. The build is once, and a later container costs about fifteen seconds.

**`--worker` is what puts the harnesses in.** The plain host answers *not found* for both — it
carries `git`, `gh` and certificates, and it grades.

### 5. Sign in, inside, once

```sh
gh auth login
claude
codex login
```

Three tools, three stores, and the place named in step 3 keeps all three. **Every login is
interactive**, so this is the step no command replaces.

### 6. Put Foundry in the host

**A clone is not an install, and step 2 gave you a clone.** `/src` is read-only, and its
`.claude/settings.json` names kernel, signal and floor as enabled.

Measured 22 September 2026, in a fresh container:

| | |
|---|---|
| `/src/.claude/settings.json` | names `kernel@the-foundry`, `signal@the-foundry`, `floor@the-foundry` |
| `~/.claude/plugins/marketplaces` | holds `claude-plugins-official`, and nothing else |

So the checkout asks for three plugins from a marketplace this machine never registered, and
**nothing in steps 1 to 5 says so.** The host starts and the harness replies with none of them.

**A project setting reaches a session started inside that project.** The shell opens in
`/home/forge`, so `cd /src` first, or the three stay off whatever else is true.

```sh
cd /src
claude plugin marketplace add attac-t/the-foundry
claude plugin install kernel@the-foundry
claude plugin install signal@the-foundry
claude plugin install floor@the-foundry
```

**Nobody has driven those lines in this container.** They are what the README installs with, and
what `plugins.sh` tells an unregistered host to run. Treat them as the thing to try. The next
section says how to see whether they worked.

**`.claude` is a kept place**, so an install that lands survives the container — the store named in
step 3, the same one holding the sign-ins. Unset `FOUNDRY_KEYS` and this step is due again every
container, exactly like the logins.

## The three are not all of Foundry

`/src` asks for three. [README.md](../../../../README.md) holds which of the rest need an install
of their own, and this page does not repeat the list.

**Floor's own code needs none of them.** Measured 22 September 2026: `run.sh charter derive` wrote
three clauses in a container carrying no plugins at all.

**What goes missing is the half a worker invokes.** `panel:craft-charter` and
`panel:decide-boundary` are skills, and a worker with no plugins reaches neither. So a charter
derives and nothing shapes it. **The deriving half works, which is what hides the other.**

Installing them is step 6's command with a different name after it, and **nobody has driven that
here either.**

## Prove it answers

A version is not a call. Leave the shell and make three calls, each from outside:

```sh
FOUNDRY_KEYS=foundry-keys sh bin/host.sh --worker sh -c 'gh api user --jq .login'
FOUNDRY_KEYS=foundry-keys sh bin/host.sh --worker claude -p 'reply with ok'
FOUNDRY_KEYS=foundry-keys sh bin/host.sh --worker sh -c 'cd /src && codex exec "reply with ok"'
```

| | |
|---|---|
| the forge | names the account the sign-in belongs to |
| the harness | replies |
| the judge | replies, and **only from a git repository** — it refuses any other directory, and says so |

**Each starts a fresh container.** So a reply proves the sign-in survived one, and not that a
shell was still warm.

**`ok` proves the harness and not Foundry.** It comes back the same on a host carrying no plugins
at all, which is what step 6 is for. One more call reads that half:

```sh
FOUNDRY_KEYS=foundry-keys sh bin/host.sh --worker sh -c 'cd /src && sh plugins/floor/lib/plugins.sh declared .'
```

Silent means the checkout and the host agree. Otherwise it names the marketplace nobody registered
and says an install from it finds nothing.

Then ask floor, which is what the host is for:

```sh
FOUNDRY_KEYS=foundry-keys sh bin/host.sh --worker sh -c 'cd /src/plugins/floor && sh bin/join.sh'
```

It ends `joined.`, or names the one thing the machine still owes. It writes nothing.

**`joined.` is not *installed*.** Join reports the plugins a rule names, and refuses on none of
them. So a host with all three missing ends `joined.` all the same. On a fresh keys store, join's
own line reads *cannot tell*, because there is no `~/.claude/settings.json` yet to read.

## When a step refuses

| Exit | What it means |
|---|---|
| 2 | Docker is not answering. Start it |
| 3 | the image would not build. Run the same `docker build` without `-q` and read it |
| 4 | the machine has no home for runs. Set `FOUNDRY_HOME`, or set `HOME` |
| 5 | the place `FOUNDRY_KEYS` names could not be prepared |

## Where to disagree

Three of the choices above belong to the machine, not to Foundry.

| | |
|---|---|
| the harnesses | drop `--worker` where a machine only grades. It is 1.3 GB lighter and cannot do the work |
| where sign-ins are kept | `FOUNDRY_KEYS=/srv/foundry-keys` puts them in a directory instead, readable with Docker stopped |
| where runs land | `FOUNDRY_HOME`, else `$HOME/.foundry`. `--volume` puts them in Docker instead, and then only Docker reaches them |

**Nothing here is baked into the image.** The identity, the home and the sign-ins are the machine's,
and they arrive when a container starts.
