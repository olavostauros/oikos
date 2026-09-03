/** @jsxImportSource jsx-md */

import { readFileSync, readdirSync, statSync } from "fs";
import { join, resolve } from "path";

import {
  Heading, Paragraph, CodeBlock,
  Bold, Code, Link, Center, Section,
  List, Item,
} from "readme/src/components";

// ── Dynamic data ─────────────────────────────────────────────
//
// Everything below is measured from the repo, not typed by hand. The counts in
// the hand-written README this replaced had all three drifted: it advertised 75
// tasks, an empty household, and a per-agent module layout that was never built.

const REPO_DIR = resolve(import.meta.dirname);

// Task groups (directories under .mise/tasks/) and the top-level tasks that sit
// beside them. Both are counted so the sentence below cannot quietly become a
// half-truth when someone adds one of either.
const TASK_DIR = join(REPO_DIR, ".mise", "tasks");
const taskEntries = readdirSync(TASK_DIR);
const taskGroups = taskEntries
  .filter((f) => statSync(join(TASK_DIR, f)).isDirectory())
  .sort();
const topLevelTasks = taskEntries
  .filter((f) => !statSync(join(TASK_DIR, f)).isDirectory() && !f.startsWith("_"))
  .sort();

// shiv packages this repo declares, read straight from [tools] in mise.toml
const miseToml = readFileSync(join(REPO_DIR, "mise.toml"), "utf-8");
const shivPackages = [...miseToml.matchAll(/^"shiv:([a-z-]+)" = /gm)]
  .map((m) => m[1])
  .sort();

// Encrypted notes. Filenames are obfuscated in the repo, so this counts blobs
// and never reads or names one.
const noteCount = readdirSync(join(REPO_DIR, "notes"))
  .filter((f) => !f.startsWith(".")).length;

// ── README ───────────────────────────────────────────────────

const readme = (
  <>
    <Center>
      <Heading level={1}>oikos</Heading>

      <Paragraph>
        <Bold>οἶκος</Bold> — <Bold>the household</Bold>: the home, its people,
        and everything belonging to it.
      </Paragraph>
    </Center>

    <Paragraph>
      Home base for a household of agents — the place they return to after
      working in the world. It is part contract, part encrypted notebook, part
      work queue: the agents read their rules here, record what they learn here,
      and hand work to each other here.
    </Paragraph>

    <Paragraph>
      Derived from <Link href="https://github.com/ricon-family/fold">ricon-family/fold</Link> —
      same machinery, different household. Their notes and their agent roster
      are not included.
    </Paragraph>

    <Section title="Who lives here">
      <Paragraph>
        Two agents, each with its own GitHub identity, its own signing key, and
        its own home repo:
      </Paragraph>

      <List>
        <Item>
          <Link href="https://github.com/olavostauros/knick-home"><Bold>knick</Bold></Link> —
          triage and correspondence. Surveys open issues, reads them properly,
          and produces a ranked argued shortlist. Also the household&apos;s
          housekeeper: branch hygiene, note accuracy, and keeping the written
          record honest. Produces judgement, not patches.
        </Item>
        <Item>
          <Link href="https://github.com/olavostauros/knack-home"><Bold>knack</Bold></Link> —
          implementation. Takes the top queued entry, reproduces it, fixes it on
          a branch in its own fork, runs the project&apos;s own gates, and opens
          a pull request upstream.
        </Item>
      </List>

      <Paragraph>
        Neither agent decides its own work: knick assigns into the queue and
        knack works from it. Neither merges anything upstream — that belongs to
        the maintainers of the repositories they contribute to.
      </Paragraph>
    </Section>

    <Section title="Install">
      <CodeBlock lang="bash">{`gh repo clone olavostauros/oikos ~/oikos
cd ~/oikos && mise trust && mise install`}</CodeBlock>

      <Paragraph>
        That is all — there is no global <Code>oikos</Code> command and no shell
        config to add. A household is a working directory, not a tool on your
        PATH.
      </Paragraph>
    </Section>

    <Section title="Usage">
      <CodeBlock lang="bash">{`cd ~/oikos
mise welcome          # orientation and setup health
mise tasks ls --all   # every task, grouped
mise run test         # test suite`}</CodeBlock>

      <Paragraph>
        Tasks live in <Code>.mise/tasks/</Code>, in {taskGroups.length} groups —{" "}
        {taskGroups.map((g) => <Code key={g}>{g}</Code>).reduce((acc: any, el, i) => i === 0 ? [el] : [...acc, ", ", el], [])}{" "}
        — plus {topLevelTasks.length} that stand on their own:{" "}
        {topLevelTasks.map((t) => <Code key={t}>{t}</Code>).reduce((acc: any, el, i) => i === 0 ? [el] : [...acc, ", ", el], [])}.
      </Paragraph>
    </Section>

    <Section title="How it is laid out">
      <List>
        <Item>
          <Bold><Code>AGENTS.md</Code></Bold> — the house contract, and the real
          documentation. House rules, review standards, and the authority model
          that says what an agent may do without asking. Agents may tighten
          their own constraints at any time; only the owner loosens one.
        </Item>
        <Item>
          <Bold><Code>notes/</Code></Bold> — {noteCount} notes, encrypted with
          git-crypt. The <Bold>filenames are obfuscated too</Bold>, so a clone
          without the key shows neither content nor subject. Edit them by their
          readable names and commit through the <Code>notes</Code> tool, which
          handles the obfuscation.
        </Item>
        <Item>
          <Bold><Code>.mise/tasks/</Code></Bold> — the household&apos;s own
          machinery: waking agents, mail, git hygiene, CI.
        </Item>
      </List>

      <Paragraph>
        <Bold>One checkout, shared.</Bold> Both agents work in this same working
        tree. The contract describes a per-agent layout at{" "}
        <Code>~/agents/&lt;name&gt;/home/modules/oikos/</Code> — that is the
        intended design and it has not been built, which is recorded as a known
        defect rather than described as fact. Switching this checkout&apos;s
        branch moves it for everyone using it.
      </Paragraph>
    </Section>

    <Section title="Tooling">
      <Paragraph>
        Managed by <Link href="https://github.com/KnickKnackLabs/shiv">shiv</Link>,
        which installs each command this repo expects and pins it in{" "}
        <Code>mise.toml</Code>. {shivPackages.length} packages are declared:{" "}
        {shivPackages.map((p) => <Code key={p}>{p}</Code>).reduce((acc: any, el, i) => i === 0 ? [el] : [...acc, ", ", el], [])}.
      </Paragraph>

      <Paragraph>
        A shiv shim only resolves where its package is declared, so each repo
        that uses one of these declares it itself.
      </Paragraph>
    </Section>

    <Section title="Starting your own household">
      <Paragraph>
        A fresh clone has the machinery and none of the household. Before an
        agent can wake in it you need, in order:
      </Paragraph>

      <List ordered>
        <Item>
          <Bold>git-crypt and a GPG key</Bold> — <Code>notes/</Code> is
          encrypted, so without a key there is nothing to read and no way to
          write. <Code>rudi install</Code> fetches git-crypt, then{" "}
          <Code>notes setup --gpg-key &lt;fingerprint&gt;</Code> initializes the
          corpus.
        </Item>
        <Item>
          <Bold>At least one agent</Bold> — <Code>shimmer agent:onboard &lt;name&gt;</Code>{" "}
          walks through the identity, then write that agent&apos;s shared
          identity note here.
        </Item>
        <Item>
          <Bold>Your own mail and CI credentials</Bold> — the mail domain and
          host are set in <Code>mise.toml</Code> and default to this
          household&apos;s. Change them before sending anything.
        </Item>
      </List>
    </Section>

    <Section title="Staying current with upstream">
      <Paragraph>
        fold is still developed. To pull improvements without re-adopting their
        household:
      </Paragraph>

      <CodeBlock lang="bash">{`git remote add upstream https://github.com/ricon-family/fold.git
git fetch upstream
git log --oneline HEAD..upstream/main
git cherry-pick <sha>       # review each one; paths and names differ`}</CodeBlock>

      <Paragraph>
        Names diverge — <Code>fold</Code> → <Code>oikos</Code>,{" "}
        <Code>ricon-family</Code> → <Code>olavostauros</Code> — so expect to
        resolve conflicts by hand rather than merging wholesale. Push to{" "}
        <Code>upstream</Code> is disabled here on purpose: the fork takes from
        it and never writes to it.
      </Paragraph>
    </Section>

    <Center>
      <Paragraph>
        {"Built with "}
        <Link href="https://github.com/KnickKnackLabs/readme">readme</Link>.
        {" README.md is generated — edit README.tsx."}
      </Paragraph>
    </Center>
  </>
);

console.log(readme);
