# /hitch-clerk: publish

Publish a branch the user built themselves as a PR, the hitch way: the description, annotations and work-item links from `SKILL.md`. No review crew, no dev deploy.

Input: `[task-id | story-id] [branch]`, both optional.

## Output rules

- No bloat: keywords, bullets, one line per fact.
- Description and annotations are read by colleagues: raw info a reviewer needs, readable like the tickets.

## Steps

1. **Branch**: the input, else the current branch of the repo in the working directory. `<default>`: `git symbolic-ref --short refs/remotes/origin/HEAD`. Stop if the branch is `<default>`. Uncommitted changes: list them and ask (commit, stash or ignore). Never commit on your own.
2. **Work item**: the input, else the ID in the branch name (e.g. `_T<id>_`, `_U<id>_`), else the one in the last commit messages, else ask. Load it as in **Read**. A Task: link it and its parent Story, its scope line is the description's first line. A Story alone: link it, the first line comes from its description and ACs. The user says none: no work-item link.
3. **Existing PR**: `az repos pr list --source-branch <branch> --status active -o json`. Found: sync mode, go to step 6.
4. **Write**: `git fetch origin`, then read `git diff origin/<default>...<branch>` in full.
   - Title and description as in **PR**. The overview is about the diff, not the commit messages.
   - Annotations as in **PR**: `<path>:<line><TAB><text>`, the line in the branch's version of the file.
   - A UI change: ask for the deployed URL and a screenshot (path, or the user's go to take one as in `hitch-mechanic`). None: leave both out. Upload after create, as in **PR**.
5. **Show** in chat: title, description, annotations as `path:line: text`. Wait for the user's OK. They may edit, drop or add. Then:
   ```bash
   git push -u origin <branch>                    # never force; rejected: report and ask
   az repos pr create --draft ...                 # as in PR, --work-items <task-id> <story-id>
   ~/.claude/skills/hitch-tower/hitch-pr annotate <pr> annotations.tsv
   az repos pr update --id <pr> --draft false     # only after the annotations: reviewers get notified here
   ```
   The user says `draft`: skip the last line.
6. **Sync** (the PR exists, e.g. after a push): push unpushed commits (never force). Re-read the diff, then propose in one block: the new description, and the annotations to edit, delete and add, as in **PR**. Only your own annotation threads. Apply on the user's OK.
7. **States**, as in the lifecycle table, and only if they aren't there yet: Task and Story `New` → `Active`, assigned to the user (someone else holds it: ask). Published: the Task to the taskboard's review column. No Task: the Story alone, no column.
8. **Report**:
   ```
   **#<id> <title>** → <pr-url>
   - <draft | published> · <n> annotations · work items: <task-id> <story-id> | none
   ```
