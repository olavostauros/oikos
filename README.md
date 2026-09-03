<div align="center">

# oikos

**οἶκος** — **the household**: the home, its people, and everything belonging to it.

</div>

Home base for a household of agents — the place they return to after working in the world. It is part contract, part encrypted notebook, part work queue: the agents read their rules here, record what they learn here, and hand work to each other here.

Derived from [ricon-family/fold](https://github.com/ricon-family/fold) — same machinery, different household. Their notes and their agent roster are not included.

## Who lives here

Two agents, each with its own GitHub identity, its own signing key, and its own home repo:

- [**knick**](https://github.com/olavostauros/knick-home) — triage and correspondence. Surveys open issues, reads them properly, and produces a ranked argued shortlist. Also the household's housekeeper: branch hygiene, note accuracy, and keeping the written record honest. Produces judgement, not patches.
- [**knack**](https://github.com/olavostauros/knack-home) — implementation. Takes the top queued entry, reproduces it, fixes it on a branch in its own fork, runs the project's own gates, and opens a pull request upstream.

Neither agent decides its own work: knick assigns into the queue and knack works from it. Neither merges anything upstream — that belongs to the maintainers of the repositories they contribute to.

## Install

```bash
gh repo clone olavostauros/oikos ~/oikos
cd ~/oikos && mise trust && mise install
```

That is all — there is no global `oikos` command and no shell config to add. A household is a working directory, not a tool on your PATH.

## Usage

```bash
cd ~/oikos
mise welcome          # orientation and setup health
mise tasks ls --all   # every task, grouped
mise run test         # test suite
```

Tasks live in `.mise/tasks/`, in 10 groups — `agent`, `analysis`, `ci`, `comment`, `git`, `github`, `homes`, `notes`, `shiv`, `skills` — plus 5 that stand on their own: `human`, `setup`, `test`, `wait`, `welcome`.

## How it is laid out

- **`AGENTS.md`** — the house contract, and the real documentation. House rules, review standards, and the authority model that says what an agent may do without asking. Agents may tighten their own constraints at any time; only the owner loosens one.
- **`notes/`** — 9 notes, encrypted with git-crypt. The **filenames are obfuscated too**, so a clone without the key shows neither content nor subject. Edit them by their readable names and commit through the `notes` tool, which handles the obfuscation.
- **`.mise/tasks/`** — the household's own machinery: waking agents, mail, git hygiene, CI.

**One checkout, shared.** Both agents work in this same working tree. The contract describes a per-agent layout at `~/agents/<name>/home/modules/oikos/` — that is the intended design and it has not been built, which is recorded as a known defect rather than described as fact. Switching this checkout's branch moves it for everyone using it.

## Tooling

Managed by [shiv](https://github.com/KnickKnackLabs/shiv), which installs each command this repo expects and pins it in `mise.toml`. 13 packages are declared: `chat`, `codebase`, `comments`, `desks`, `emails`, `modules`, `notes`, `readme`, `rudi`, `sessions`, `shell`, `shimmer`, `websites`.

A shiv shim only resolves where its package is declared, so each repo that uses one of these declares it itself.

## Starting your own household

A fresh clone has the machinery and none of the household. Before an agent can wake in it you need, in order:

1. **git-crypt and a GPG key** — `notes/` is encrypted, so without a key there is nothing to read and no way to write. `rudi install` fetches git-crypt, then `notes setup --gpg-key <fingerprint>` initializes the corpus.
2. **At least one agent** — `shimmer agent:onboard <name>` walks through the identity, then write that agent's shared identity note here.
3. **Your own mail and CI credentials** — the mail domain and host are set in `mise.toml` and default to this household's. Change them before sending anything.

## Staying current with upstream

fold is still developed. To pull improvements without re-adopting their household:

```bash
git remote add upstream https://github.com/ricon-family/fold.git
git fetch upstream
git log --oneline HEAD..upstream/main
git cherry-pick <sha>       # review each one; paths and names differ
```

Names diverge — `fold` → `oikos`, `ricon-family` → `olavostauros` — so expect to resolve conflicts by hand rather than merging wholesale. Push to `upstream` is disabled here on purpose: the fork takes from it and never writes to it.

<div align="center">

Built with [readme](https://github.com/KnickKnackLabs/readme). README.md is generated — edit README.tsx.

</div>
