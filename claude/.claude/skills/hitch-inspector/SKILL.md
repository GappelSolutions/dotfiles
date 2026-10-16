---
name: hitch-inspector
description: Inspect how the hitch crew behaved since the last inspection. Measures loops, slow steps, errors, your corrections and PR outcomes from the transcripts and Azure, compares them with the previous scorecard, and proposes concrete edits to the hitch skills and agents.
argument-hint: "[since YYYY-MM-DD] [--all]"
disable-model-invocation: true
---

# hitch-inspector

Input: `$ARGUMENTS`. The default is since the latest scorecard in `~/.hitch/inspections/`, or else the last 7 days. `--all` adds the non-hitch sessions as a baseline.

Output: no bloat. Every claim cites a ref (`<file-key>:<line>`).

## Steps

1. **Extract**: `~/.claude/skills/hitch-inspector/extract --since <date> [--all] > /tmp/hitch-inspection.md`, then read it. Refs resolve through its Files section. Read a transcript line with `sed -n '<line>p' <file> | jq`.
2. **PRs**: `~/.claude/skills/hitch-tower/hitch-pr stats <every id in ## PRs>`, then `~/.claude/skills/hitch-inspector/comments <same ids>`: every comment each final diff adds, against the CODE.md budget, tagged with the patterns a script can tell. Only the tower's PRs (`by=` you) measure the crew; hitch-jury PRs are colleagues' code.
3. **Prompts**: classify every entry in ## Prompts, using `before` for context:
   - `correction`: the crew went the wrong way, or did more or less than asked.
   - `redo`: the same thing asked again.
   - `avoidable`: the crew asked something the code, Azure or the brief already answered.
   - `flag`: starts with `#flag`, the user's own marker.
   - `ok`: answers, approvals, new asks.

   Every class except `ok` is an incident.
4. **Causes**: group the incidents (the extract's and yours) by root cause, not by occurrence. Per group, open the refs and find what led there: an instruction in a hitch skill or agent file (path:line), a missing rule, or the environment (shell aliases, missing tools, auth). Loops and error streaks that other sessions share are environment problems.
5. **Scorecard**, compared with the previous one:

   ```
   **Scorecard** <since> → <until> (vs <previous>)
   | metric | now | before |
   ```
   Metrics, per PR (Task = PR) where it applies:
   - Outcome: their comments, pushes after publish, negative votes, publish→approve.
   - Your load: corrections + redos + avoidable, interrupts, draft→publish.
   - Comments: added per PR, over budget, tagged (`docstring→banned`, `history`, `banner`, ...) and `[-]` that fail the CODE.md test anyway.
   - Reviews: runs per tier (`none`/`one`/`full`, and reruns), fixes, dropped (skeptic false positives); at `full` found by `A+B`, `A` or `B` alone, and `referee` alone.
   - Cost: agent work time, main-session work time, $, compactions.
   - Friction: tool error rate, loops, error streaks, slow calls, rework files, denials.
6. **Report**:

   ```
   **Pitfalls** (costliest first)
   1. <pattern> ×n: <refs>. Cause: <path:line | missing rule | env>. Change: <one line>.
   **Slow**: top 3 by time, with cause
   **Keep**: ≤3 lines of what worked
   **No-ops**: hitch instructions the transcripts never show changing behavior: path:line, proposed deletion
   **Proposed edits**: <file>: <change>
   ```
   Read the review metrics like this: their comments on a `none` or `one` PR that a `full` review would have caught mean the tier triggers are too loose; `full` runs with few fixes mean too tight. A high `A` or `B` alone justifies two skeptics. `A+B` near 100% means one would do. A high `referee` alone means the lens misses things. A high dropped means noise.
   Comments: every one on a tower PR that fails CODE.md got past the mechanic and the review at its tier. Find which one saw it and let it through.
   Model trials:
   - Mechanic on opus · low since 2026-10-16 (sonnet · high trial 2026-10-14..16 dropped: no cost saving, worse output). UI design work: opus · high. Per Task: **Open** escalations, corrections + redos on mechanic output, review fixes, comments over budget, rework commits, agent time, $, vs baselines `retro-2026-10-08.md` (opus · high), `usage-2026-10-14.md`. More fixes/corrections or guessed decisions: find whether the Design was thin (fix the duck) or the effort (propose high). Never propose sonnet.
   - Short-lived mechanics since 2026-10-14 (one run each, slow checks and dev in gofers, 2 mechanics per tower; baseline `usage-2026-10-14.md`: 77 rewrites/$38 from long Bash calls + 54/$28 from SendMessage follow-ups per week, peaks of $40–51/h with 7 mechanics). Measure: mechanic rewrites after >5 min idle and their $, peak $/h, session-limit hits, Task lead time (queueing). Queueing hurts lead time: propose 3.
   - Scout on opus · low since 2026-10-16: duck corrections caused by a wrong scout fact.
   - Skeptic A runs on opus · high, B on opus · low. Compare `A` alone vs `B` alone and dropped `A` vs `B`. B about equal to A: propose low for both. B clearly lower: propose high for B again.
7. **Save** the scorecard and the pitfalls (not the raw extract) to `~/.hitch/inspections/<until>.md`. It's the next baseline.
8. **Edits**: only on the user's OK. Make them in the dotfiles repo (`claude/.claude/...`), never in the deployed files.
