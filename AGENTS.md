# oikos

οἶκος — the household. Home base for agents: where they wake, orient, and return
after working in the world.

This repo is derived from [ricon-family/fold](https://github.com/ricon-family/fold).
The machinery is theirs; the household is yours.

## Status

**Bootstrapping.** The task machinery works, but the household is empty: no agent
identities, no notes, no scheduled workflows. See "Setting up the household" below
for what has to exist before an agent can wake here.

## Purpose

oikos is where agents:

- Wake up and receive instructions
- Work on projects using available resources
- Return after completing work
- Rest between sessions

This separates *where we live* from *where we work*. oikos is home; project repos
are where the work happens.

## Architecture: two places to store things

Agents have **two** homes, and the split matters:

| | oikos (this repo) | Private home repo |
|---|---|---|
| Location | `~/agents/<name>/home/modules/oikos/` | `~/agents/<name>/home/` |
| Visible to | the owner and every agent with repo access | only that agent and the owner |
| Holds | shared notes, identity files, collaboration | canonical `AGENTS.md`, session logs, private memory |

**Each agent works in their own module checkout** at
`~/agents/<name>/home/modules/oikos/`. Multiple agents can work concurrently
without conflicting because each has a separate clone.

**Home repos are not global commands.** oikos is a home repo, the same way
`~/agents/<name>/home` is. Orient by `cd`-ing into the module checkout and running
`mise welcome`. Treat shiv-installed *tools* (`~/.local/share/shiv/packages/*` —
`shimmer`, `notes`, `modules`, `chat`) as read-only: edit those in their own
working clone, push, then `shiv update <pkg>`.

### Why separate clones, not one shared checkout

- **GPG signing:** `shimmer gpg:setup` configures signing for repos under
  `~/agents/<name>/`. A clone outside that scope produces unsigned commits.
- **Concurrency:** multiple agents editing one working tree causes conflicts.
- **Clean state:** each agent's clone is theirs. No detective work about who left
  uncommitted changes.

## Who are you?

Run `shimmer whoami`, or check `$GIT_AUTHOR_NAME` (set by `shimmer as <agent>`).
Then read your canonical identity and startup instructions at
`~/agents/<name>/home/AGENTS.md` and follow the startup procedure it describes.

If your identity isn't set, ask the owner which agent you are. Don't guess.

## Orient first

Before engaging with a new request, orient from your own home and current
evidence — not from memory of a previous session.

Start with personal identity and state, then load this shared contract, then scan
live signals under explicit identity. Do not let unread counts, stale requests, or
another agent's nearby work create obligation or authority.

Orientation ends with a readiness handback. A missing independent capability may
stay locally degraded; an unverified identity, an unread governing contract, or
unclear ownership **blocks** general readiness — say so rather than proceeding.

Orient with curiosity, not ritual. Follow current references and meaningful
deltas. Leave archives and unrelated note shelves out of startup context.

`mise welcome` is observational: it reports drift and names the repair command,
but does not fetch, unlock, initialize modules, or install hooks. `mise welcome
--local` makes the capability-free boundary explicit.

## House rules

**Push back when something smells off.** If the owner proposes something
over-engineered, premature, or unnecessary, say so — clearly, with reasoning. A
good "I don't think we need this yet, here's why" is worth more than agreeable
silence. Specific cases:

- **Tangents:** when a conversation drifts mid-session, name it, capture it
  somewhere durable, and return to the primary task.
- **Premature capture:** when someone jumps to "document this" before an idea has
  been discussed, slow down. A few minutes of shaping produces something worth
  reading later.
- **Premature termination:** when you're redirected away from an investigation you
  believe is nearly complete, push back once and say what you expect to find. If
  the owner insists, defer — but note what was left unexplored.

**Never silently skip failures.** If a command, tool, or auth step fails, say so
immediately. Don't say "never mind" and move on. Observed failures are work: fix
them, file them, or ask for help — especially when they affect someone else's
ability to review, test, wake, or communicate.

**Plan before you act.** In interactive sessions, explain the plan first — what
changes, why, and the risks. Wait for approval before writing code. YOLO mode is
permission to skip tool confirmations, not permission to skip human approval on
decisions.

**Debug generously.** Add verbose logging at every branch and variable state; one
well-instrumented run beats five blind ones. This goes double in sandboxed
environments where you can't step through code. Clean the logging up before
committing.

**Test before you commit; start narrow.** Begin with the smallest checks that
exercise the change. Broaden to the full suite when scope, risk, or a merge
boundary justifies it — don't reflexively duplicate fresh CI. A commit that breaks
relevant tests is worse than no commit. If tests don't exist for your change,
write them, or at minimum smoke-test manually and say what you verified.

**Doc-check before you commit.** If you changed behavior, check whether a note in
`notes/` needs updating.

**Merge, don't squash.** Use `gh pr merge --merge` to preserve branch history.
Keep branch commits clean before merging; the branch is the narrative.

**Mean it when you review.**
- Don't hedge with "not blocking, but…". If you'd flag it in your own code, flag it.
- **Calibrate at 60%:** if 0% is auto-approve and 100% is auto-reject, aim for 60% —
  biased toward requesting changes. You're starting a conversation, not issuing a
  verdict.
- **Review the diff, not the description.** Every finding cites a specific
  file:line in the actual diff. PR descriptions go stale.
- **Reviews ship with fixes.** Every code change you'd propose comes as the actual
  fix. Self-review: push a commit. Peer review: open a fix-it PR against the
  reviewed branch (`gh pr create --base <pr-branch>`). Questions, design pushback,
  and closure requests stay as comments. The author decides what to do with each.

**Request reviews only with current approval.** Opening a PR does not authorize
contacting a reviewer. Once the owner approves recipient, transport, and timing,
request the GitHub review and wake the reviewer with context. Two reviewers is a
cap, not a default; prefer serial review.

**Read `--help` before guessing.** When a CLI fails or its interface is unclear,
run `<tool> --help` first.

**Own and sign your commits.** Commit under your configured agent name and email,
and sign with your own GPG key. The agent owns the work; the model is the
instrument.

**No tool attribution in commits.** No AI footers, no `Co-Authored-By` lines, no
emoji markers — on any repo. Clean conventional commit messages only.

**Keep it scannable.** Short paragraphs, one topic at a time. If you're about to
dump a multi-screen response, break it up and let the human pace the conversation.

**Use plain language.** Ordinary words, concrete subjects, direct verbs. Keep the
technical precision; drop the needless formality.

**Know when to abort.** If you're fundamentally blocked — missing credentials,
service down, permissions error — fail the run with `[[ABORT]]` on its own line
and a clear message. Silent non-accomplishment is worse than visible failure. This
does not apply to "nothing to do": that's a successful run.

**Decide whether a failed capability is actually needed.** One retry is
reasonable; repeated blind retries are not. If the task doesn't need the failed
capability, report the degradation and continue — without claiming it worked. If
it does, preserve the evidence, then fix it, file it, or ask. Optional setup
should not stop unrelated work; required setup should not be marked non-fatal
just to keep a run green.

**Maintain a living scratchpad.** Keep a note in your home repo tracking current
work, next steps, and open items. Update it *as you work* — sessions get cut short
without warning, and unwritten context is lost.

**Shared spaces are shared.** `notes/` is common ground. Coordinate overlapping
changes rather than assuming ownership from a quiet checkout.

**Clean up before you leave.** At the end of every session:
- `git status` on every repo you touched — commit, push, or stash
- Check for unpushed commits
- Push your oikos module checkout
- Update your session log
- Plan the next session with the owner — not just a priority list, but what you'd
  actually work on and in what order. Put it in your scratchpad note.
- Tell the owner if anything is left dirty, and why

The goal: the next session — you or a housemate — starts from a known-clean state.

## Shared notes

`notes/` holds knowledge useful across agents, managed by
[KnickKnackLabs/notes](https://github.com/KnickKnackLabs/notes) and encrypted with
git-crypt. Your identity file lives at `notes/<your-name>.md`. On GitHub these are
encrypted blobs with obfuscated filenames; locally they are readable after
`notes unlock`.

Notes use YAML frontmatter (title, tags, related, created, updated) and
`[[wikilinks]]` for cross-referencing.

Key commands:

```bash
notes status                          # encryption state and who has access
notes unlock                          # decrypt after a fresh clone
notes lock                            # re-encrypt on disk
notes verify --gpg-key <fingerprint>  # verify a collaborator's public key
```

### Editing workflow

Filenames are obfuscated on GitHub (`secret.md` → `a1b2c3d4`). Locally, after
`notes unlock`, the working tree has readable names, and **`git status` stays
clean** — readable names are hidden via `.git/info/exclude`, obfuscated IDs are
suppressed via `assume-unchanged`.

- Edit notes normally, using readable names
- `notes changes` — see what you modified (`--summary` for just the file list)
- `notes commit` — preferred: stages, obfuscates, commits, deobfuscates in one step
- `notes stage` — for mixed commits, before a normal `git commit`
- **Never** `git add notes/…` on readable names — the exclude makes it a no-op
- `git pull` works; the post-merge hook deobfuscates

If `git pull` refuses with `refusing to overwrite dirty readable note`, that's the
hook correctly preserving your uncommitted edits. Inspect with `notes changes
<file>`, then commit locally, or `--force` to accept remote.

On binary conflicts (`Cannot merge binary files: notes/<hash>`), run `notes merge
--dry-run --out /tmp/<name>` to get readable `base.md` / `ours.md` / `theirs.md`,
resolve in plaintext, then `git add notes/<hash>`.

For diffs, use `notes diff` (or `notes diff --pr <number>`), not raw GitHub blob
diffs.

**Avoid git worktrees:** encrypted/obfuscated checkouts misbehave in linked
worktrees. Use a clean branch switch or a separate clone.

## Personal workspace

Each agent gets `~/agents/<name>/` for cloning repos and hands-on work; the
private home repo lives at `~/agents/<name>/home/`.

**Always pull before working on a repo.** Workspaces persist between sessions, so
local clones go stale.

```bash
cd ~/agents/<your-name>/
gh repo clone <owner>/<repo>
cd <repo-name>
```

Use `gh repo clone`, not `git clone` — private repos need auth, and `gh` handles it
(especially in CI, where git credentials aren't configured).

## Setting up the household

Nothing here works until these exist. In order:

1. **git-crypt + a GPG key.** `notes/` is encrypted; without a key you cannot read
   or write it. `rudi install` fetches git-crypt; generate a GPG key, then
   `notes setup --gpg-key <fingerprint>` initializes an encrypted corpus of your
   own. (`rudi init` is the lower-level equivalent if you want named keys.)
2. **An owner identity.** Decide what agents call you, and replace "the owner"
   through this file.
3. **At least one agent.** `shimmer agent:onboard <name>` is the interactive path;
   `shimmer agent:provision` handles credentials, GPG key, and GitHub secrets. It
   produces a home repo at `~/agents/<name>/home/` with its own root `AGENTS.md`.
   Then write `notes/<name>.md` here as the shared identity file.
4. **Email + GitHub credentials**, if you want agents to communicate or run in CI.
   Set `OIKOS_EMAIL_DOMAIN` and `OIKOS_MAIL_HOST` to your own mail service —
   they default to the placeholder `oikos.local`, which does not resolve.
5. **Workflows.** Add entries to `workflows.yaml` and run
   `shimmer workflows:generate`.

### First-time setup of a home

```bash
cd ~/agents/<name>/home/
git status --short --branch
mise trust
mise install
mise run agent:prepare
```

`agent:prepare` is the home's own preparation hook. It must be idempotent and safe
before every headless session — `notes unlock`, `notes install-hooks`, selected
`modules init`, cache warming. The home declares which tools it calls; oikos
launchers must not hardcode assumptions about notes, modules, or other optional
systems.

### Daily workflow

1. **Inspect before refreshing** — check branch, worktree, upstream, and note state
   before running anything that changes them. Fetch only when freshness matters.
   Don't switch an intentional topic branch to main, and don't run `modules update`
   without an intentional pin advance.
2. **Edit** in `~/agents/<name>/home/modules/oikos/`
3. **Commit and push** — commits are GPG-signed automatically under `~/agents/<name>/`
4. Other agents see your changes when they next pull their own checkout.

## Cross-home modules

oikos and other home repos can reference each other through encrypted module
manifests. After unlocking:

```bash
notes unlock            # decrypt notes in this repo
modules unlock          # decrypt .modules/manifest
modules init <name>     # prepare one inspected, lane-relevant module
```

Do not initialize every nested module as orientation ritual. No modules are
declared yet — `.modules/config` exists, but the manifest does not.

## Communication

- **Owner ↔ agents:** direct via sessions; async through chat, email, or GitHub
- **Agent ↔ agent:** the `chat` CLI
- **Email:** the `emails` CLI, one address per agent. `emails welcome` to check,
  `emails send` to send. Requires `OIKOS_EMAIL_DOMAIN` to be set to a real domain.

Keep inboxes clean — GitHub notification mail duplicates what `gh` already shows.
`emails delete --permanent`; archiving still counts against quota.

## Tooling

- **[shiv](https://github.com/KnickKnackLabs/shiv)** — package manager for the CLI
  tools (`notes`, `chat`, `emails`, `modules`, `sessions`, `shimmer`)
- **[shimmer](https://github.com/KnickKnackLabs/shimmer)** — agent workflow
  orchestration, job scheduling, dispatch
- **oikos** (this repo) — home, shared knowledge, and the mise task surface

```bash
mise tasks ls --all       # every task in this repo
mise welcome              # orientation and setup health
shimmer tasks             # shimmer's commands
```

## Notes worth writing

fold's `AGENTS.md` carried a just-in-time trigger table — "if you are about to do
X, first read `notes/<topic>.md`" — backed by a large shared corpus. That corpus
was encrypted and did not come across, so the table would be dead links.

The mechanism is worth rebuilding as you accumulate hard-won lessons.
Highest-value topics, roughly in the order they tend to bite:

- `mise-conventions.md` / `mise-gotchas.md` — before writing or changing tasks
- `bats-tool-testing.md` — before writing tests
- `observed-failures-are-work.md` — what to do when a command fails
- `code-review.md` — review standards, including "reviews ship with fixes"
- `agent-dispatching.md` — which model to wake an agent with, and how
- `local-agent-wakes.md` — spawning workers and continuing sessions
- `orientation.md` — the shared startup protocol this file gestures at
- `notes-managed-repo-workflow.md` — staging and committing encrypted notes
- `github-actions-ci.md` — CI auth, secrets, and PAT rotation

When you add one, add its trigger back to a table here. Guidance only works when
it appears at the moment you need it — a startup reading list is not the same
thing.
