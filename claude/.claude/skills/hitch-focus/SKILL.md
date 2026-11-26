---
name: hitch-focus
description: Turns a PR into a map a reviewer reads instead of the raw diff - vertical slices in reading order, each drawn as the flow its code runs (steps, decisions, exits, loops; no code), the points of variance pinned on them (where the code makes a choice a competent reviewer could make differently and the outcome matters, with the alternative and its trade-off), what the change does when run, and what is safe to skim; tests left out. Rendered as cards in T3 Code's chat and as a flow buffer in vis, the diff one key below. Not a bug hunt. hitch-tower and hitch-jury run it for every PR they hand to the user; /hitch-focus <pr-id> runs it on any PR, anyone's.
argument-hint: "<pr-id> | <worktree> <base>"
---

Steer a human review: what the PR does as a few blocks of logic, where judgment went into it, what else could have been done, and what it costs if the choice is wrong. Read-only: never comment on Azure, never edit code. `hitch-map` means `~/.claude/skills/hitch-focus/hitch-map` (`--help` has the format).

## Input

- `<pr-id>`: `az repos pr show`, then in a local clone of its repo `git fetch origin <source> <target>`: repo = the clone, base `origin/<target>`, head `origin/<source>`. Its description, its linked Task and Story (Design, ACs) as in `~/.claude/skills/hitch-clerk/SKILL.md`, read-only.
- From hitch-tower: the worktree (repo, head `HEAD`), the base, the brief, the hand-offs (their **Open** and **Notes**) and the review results. From hitch-jury: the worktree, base `origin/<target>`, head `origin/<source>`, the brief. Decisions a review already settled stay settled; name them only when they still carry a risk the user should know.

## Read

`hitch-map hunks <repo> <base> <head>`: the diff with `### <id> <kind>` over every hunk. Kinds the script decided:
- `test`: hidden from the user. Never read, group or cite tests; the reviewers judge them.
- `generated`, `binary`, `mechanical` (whitespace only, moved unchanged, renamed): bodies omitted, listed as skim. A tagged hunk joins a block only when it carries logic (code moved and changed is not `moved`).
- `-`: yours to group.

Then the code around each hunk, as far as the logic needs. `calldiff diff <base> <head>` maps rewired call paths when the diff changes calls in code (syntactic, a map, never proof; skip it when it errors).

## Blocks: slices

Every `-` hunk lands in exactly one block. A block is a vertical slice: one behavior end to end, through every project it touches. Its contract, config keys, code, deploy template and docs go together, never split by project, layer or file (the script tags each block with the projects it runs through).
- `title`: ≤8 words, the behavior ("Retry by pause, then DLT"), not the parts ("Kafka contract", "Templates"). `name`: 1-3 words of it for the overview ("consumer loop").
- `what`: one plain sentence, what is different when it runs ("New loop: a failed record pauses its partition and is retried, then dead-lettered."). Reviewers misread less with it.
- `takes`, `gives`: what the slice hands on, short contract names (topic `dlms.plain`, config key `MESSAGING_BROKER`, route, table). A slice that gives what another takes is drawn as a chain in the overview; `gives` also shows on the card.
- `flow`: the slice's logic as steps (below). It is what the user reads; the code is one key away.
- `logic`: only when a flow can't say it (a pure contract or config change): one line, inputs, rule, effect.
- `hunks`: in reading order: the contract or config key, the rule, its wiring, then deploy.
- A part several slices share goes with the first that needs it. It becomes its own slice only when it is a behavior on its own (a library API with several callers).
- `after`: the slices it builds on. Reading order follows it, then the order given: among slices free to go either way, the riskiest (most focus points, one-way doors) first, since attention drops with every slice. The map's `order`: one sentence why this order.
- Size: ~250 changed lines at most; split a bigger one along the behavior's steps (send path, failure path), never along projects. Wiring along an existing pattern is one slice, however many files.

## Flow: the slice as a state machine

What the code does when it runs, drawn the way the author would on a whiteboard: steps, decisions, exits, loops. Not the code's structure: no classes, methods, files or syntax. Names only where they are the contract (topic, queue, config key, route, table).
- step: `{"do": "<≤4 words, verb first>", "at": "path:line", "change": "new|changed|gone"}`. `at` is the head line that acts (the call, the produce, the throw), not its catch or declaration; none for `gone`. It may lie outside the diff.
- `detail`: ≤6 words the step needs to be judged (a limit, a window: "5 s-5 min"), shown greyed after `do`. Everything else is the code's.
- `who`: where it runs, one word (service, worker, handler, Kafka, DB); shown where it changes, so a hop between services is visible. Set it on every step whose actor differs from the step before.
- `was`: on a `changed` step, the old behavior in ≤6 words, shown struck through under it.
- `change` is about behavior, not code: code moved or wrapped that does what it did is context (no `change`), and nothing is `gone` unless the behavior is. Context only where it connects changed steps (where the flow enters, where it hands off).
- decision: a step with `"when": [{"if": "<≤2 words>", "then": [steps]}]`. A branch falls through to the next step unless it ends in `"kind": "stop"` or a `to`. Config that switches behavior is a decision ("broker?"), never one step per file; a switch acting in several places is repeated where it acts, each pinned there.
- `"kind": "out"`: leaves the process (topic, queue, DB, HTTP). `"kind": "stop"`: ends the path (error, drop, exit). Either can carry `when` too (a produce and its ack).
- jump: `{"to": "<id>"}`, with `"id"` on the target step: back is a loop, drawn as a line from the step before it to the target; forward a skip, `→ <n>` (steps are numbered).
- 3-12 `do` steps per slice. More: the slice is two behaviors, split it.
- A focus point's `at` is the `at` of the step it questions: the step shows its ★.

```json
"flow": [
  {"do": "receive push frame", "who": "listener", "at": "src/Listener/Handler.cs:40"},
  {"do": "key by LDN", "change": "changed", "was": "key by serial", "at": "…"},
  {"do": "broker?", "at": "src/Listener/Program.cs:44", "change": "new", "when": [
    {"if": "rabbitmq", "then": [{"do": "publish push.plain", "kind": "out", "at": "…"}]},
    {"if": "kafka", "then": [
      {"id": "send", "do": "produce dlms.plain", "detail": "idempotent, acks=all", "who": "Kafka", "kind": "out", "change": "new", "at": "…"},
      {"do": "acked?", "detail": "within 30 s", "change": "new", "at": "…", "when": [
        {"if": "timeout", "then": [{"to": "send"}]},
        {"if": "fatal", "then": [{"do": "stop the pod", "kind": "stop", "change": "new", "at": "…"}]}]}]}]}
]
```

## Points of variance

A point qualifies only if all hold:
- **A real choice**: a concrete alternative exists that a competent reviewer could prefer (not a bug, not style; bugs are the skeptic's).
- **It matters**: getting it wrong costs throughput, data, ordering, operability, a contract, or a later rewrite.
- **Not settled upstream**: the Story's Design doesn't already decide it. When the code goes beyond or against a Design decision, that is a point, and the D line is cited.

Where to look:
- concurrency and throughput model: sequential vs parallel, per-record vs batched I/O, awaited round trips in a loop
- failure semantics: retry vs drop vs dead-letter, what blocks what while retrying, what is lost on a crash, at-least-once duplicates
- ordering, idempotency, keys and partitioning
- defaults and limits: timeouts, retry windows, pool and buffer sizes, caps, and who they hurt
- contracts and persisted shapes: message, schema, API, config keys (one-way doors)
- operability: health and readiness semantics, what an operator sees when it breaks (logs, metrics, DLT reasons), misconfiguration that starts silently
- scope cuts and deviations: what the PR leaves out, where it departs from the repo's pattern or the Design
- assumptions about the environment that tests don't cover

Rank by cost-if-wrong × how hard it is to reverse. At most 5; fewer is better. `chosen`, `instead`, `tradeoff`, `look`: ≤15 words each, the cards show them as written. Each pins to its block and a `path:line` in the head version: open it yourself.

## Effects

What the change does when built or run, where it's cheap to get. Each is a line of facts, breaking or lossy first, plus the raw output as a file under `/tmp/hitch-focus/<repo>-<head>/`. None applies: no effects.
- **Nix** (`*.nix`, `flake.lock`): per host whose config the diff touches, compare `nix eval --raw <flake>#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` at base (`git worktree add --detach /tmp/hitch-focus/base-<sha> <base>`, removed after) and head. Equal: no effect. Different: build both (`nix build --no-link --print-out-paths`), `nvd diff <old> <new>`. A build over ~10 min: skip it, say so.
- **Rendered manifests** (`rendered/` in Infra): per resource kind/name: added, removed, changed fields.
- **API**: a generated client in the diff (`libs/*/api/src/lib/generated/` in mmgdm) is the contract's effect: operations and types added, removed, changed. Without one, from endpoint and DTO hunks: routes, request and response shapes.
- **Migrations**: the `Up()` operations as a list: tables, columns, indexes, data-moving SQL; drops and type changes first.
- **Messages**: changed message types, queues, exchanges, routing keys, and which side (producer, consumer) ships first.
- **UI**: the screenshot paths you were given.

## Write the map

`/tmp/hitch-focus/<repo>-<head>/in.json`, then `hitch-map build <it>` until it exits 0. It checks every `-` hunk sits in one block, no test is in one, the flows' shape and word limits, and every step's and focus point's `at` exists.

```json
{"repo": "<path>", "base": "<base>", "head": "<head>", "pr": 123, "url": "<pr url>", "title": "<pr title>",
 "intent": "<what the PR is for, from the Task/Story, one line>", "order": "<why this reading order, one sentence>",
 "blocks": [{"id": "B1", "title": "", "name": "", "what": "", "takes": [], "gives": [], "flow": [], "hunks": ["<id>"], "after": []}],
 "focus": [{"block": "B1", "title": "<the choice, ≤8 words>", "at": "path:line", "chosen": "", "instead": "",
            "tradeoff": "<cost of each, one line>", "look": "<the scenario that shows whether it's right>", "door": "one-way"}],
 "effects": [{"title": "", "layer": "contract", "summary": "", "file": "<raw output>"}],
 "settled": ["<choice> (<Design D<n> or review>)"]}
```

Then `hitch-map html <map>`: writes the cards, prints their path. Running in the user's session (not as a subagent): show them in the chat, `html_preview` with the path for its `contentHeight`, then `html_render` with the path, that height and the PR title. Steps link into T3's PR panel. As a subagent: put the path in the report, the caller renders it.

## Report

```
**Focus #<pr>**: <n> slices · ~<lines> lines to read · <html path> · vis <Space>m
1. **<the choice, ≤8 words>** ([<file>:<line>](<pr url>#diff-<sha256 of path>R<line>), <one-way|two-way>): <chosen> over <instead>; <trade-off>
…
**Effects**: <title>: <summary> · …
```

Links open the PR in T3 Code's PR panel at that line only in this form: the PR's Azure URL, `#diff-`, the sha256 of the repo-relative path (no leading slash; `printf %s <path> | sha256sum`), `R<line>` in the head version (`L<line>` for a removed line). Never a local worktree path or `?_a=files&path=`: T3 opens neither.

One line per point, plain words, no code, no praise, no summary of the PR: the cards have the slices, the look-at scenarios and the settled choices.
