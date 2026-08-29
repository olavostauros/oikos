# oikos

> οἶκος — *the household*: the home, its people, and everything belonging to it.

Home base for agents. The place they return to after working in the world.

Derived from [ricon-family/fold](https://github.com/ricon-family/fold) — same
machinery, different household. Their encrypted notes and agent roster are not
included.

## Install

```bash
gh repo clone olavostauros/oikos ~/oikos
cd ~/oikos && mise trust && mise install
```

That's it — there is no global `oikos` command, and no shell config to add. Home
repos are working directories, not tools on your `PATH`.

## Usage

```bash
cd ~/oikos
mise welcome          # orientation and setup health
mise tasks ls --all   # all 75 tasks
mise run test         # test suite
```

Agents don't use this clone directly. Each one gets its own checkout at
`~/agents/<name>/home/modules/oikos/`, so several can work at once without
stepping on each other. See [AGENTS.md](AGENTS.md) for why.

## Status

The task machinery works. The household is empty — no agent identities, no notes,
no scheduled workflows. Before an agent can wake here you need, in order:

1. **git-crypt and a GPG key** — `notes/` is encrypted; without a key there is
   nothing to read and no way to write. `rudi install` fetches git-crypt, then
   `notes setup --gpg-key <fingerprint>` initializes the encrypted corpus.
2. **At least one agent** — `shimmer agent:onboard <name>` walks through it, then
   write the shared identity file at `notes/<name>.md` here.
3. **Your own mail and CI credentials** — `OIKOS_EMAIL_DOMAIN` and
   `OIKOS_MAIL_HOST` default to the placeholder `oikos.local`, which does not
   resolve.

[AGENTS.md](AGENTS.md) is the real documentation: architecture, house rules, the
encrypted-notes workflow, and the full setup sequence.

## Tooling

Managed by [shiv](https://github.com/KnickKnackLabs/shiv), which installs the CLI
tools this repo expects (`notes`, `chat`, `emails`, `modules`, `sessions`) and
[shimmer](https://github.com/KnickKnackLabs/shimmer), which handles agent
orchestration and scheduling.

## Staying current with upstream

fold is still developed. To pull improvements without re-adopting their household:

```bash
git remote add upstream https://github.com/ricon-family/fold.git
git fetch upstream
git log --oneline HEAD..upstream/main
git cherry-pick <sha>       # review each one; paths and names differ
```

Names diverge — `fold` → `oikos`, `ricon-family` → `olavostauros` — so expect to
resolve conflicts by hand rather than merging wholesale.
