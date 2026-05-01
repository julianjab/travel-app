---
name: take
description: >
  Pick up an issue from the Vamos backlog and start working on it in an isolated
  worktree. Reads the issue from GitHub, creates the worktree with a branch
  following the `<ID>-<slug>` convention, moves the Project card to "In
  progress", and drops the issue body into the worktree as context for the
  agent that follows.
  Triggers: "/take 14", "/take F1-06", "tomar issue 14", "arrancar la 14",
  "vamos por F1-06". Does NOT merge or open a PR — use /done for that.
argument-hint: "<issue-number-or-ID> [--base main]"
disable-model-invocation: false
---

## /take — Start working an issue

Picks an issue from `julianjab/travel-app`, creates an isolated worktree, and leaves everything ready so the next agent can work without losing context.

**Repo:** `julianjab/travel-app`
**Project:** `Vamos MVP` (#1, owner `julianjab`)
**Branch convention:** `<ID>-<slug>` — e.g. `F1-06-onboarding-miembro`

---

## Arguments

`$ARGUMENTS` may be:

| Form | Example | Behavior |
|---|---|---|
| Issue number | `14` | `gh issue view 14` |
| Backlog ID | `F1-06` | Find issue whose title starts with `[F1-06]` |
| Empty | _(nothing)_ | List `Todo` issues in milestone `MVP Caso 0` and ask which one |

Optional flag: `--base main` (default).

---

## Steps

Run in order. Abort if any step fails.

### 1. Resolve the issue

```bash
unset GH_TOKEN GITHUB_TOKEN
```

- If `$ARGUMENTS` is a number → `ISSUE_NUM=$ARGUMENTS`.
- If it matches `^[A-Z]+[0-9]*-[0-9]+$` (e.g. `F1-06`):
  ```bash
  ISSUE_NUM=$(gh issue list --repo julianjab/travel-app --state all \
    --search "[$ID]" --json number,title \
    --jq ".[] | select(.title | startswith(\"[$ID]\")) | .number" | head -1)
  ```
- If empty → show `gh issue list --repo julianjab/travel-app --milestone "MVP Caso 0" --state open --label mvp` and ask which one.

Validate: `ISSUE_NUM` not empty. Otherwise abort with a clear message.

### 2. Read the issue

```bash
gh issue view $ISSUE_NUM --repo julianjab/travel-app \
  --json number,title,body,labels,milestone,assignees,url > /tmp/take-issue.json
```

Extract:
- `TITLE` (includes `[ID]` at the start)
- `ID` — first match of `\[([A-Z0-9-]+)\]` in the title
- `SLUG` — slugify the rest of the title (lowercase, no accents, spaces → `-`, max 40 chars)
- `BRANCH` = `$ID-$SLUG` (e.g. `F1-06-onboarding-miembro`)

### 3. Create the worktree

Reuse the existing skill:

```
/worktree init $BRANCH --base main
```

(Or run directly with `git worktree add ../.worktrees/$BRANCH -b $BRANCH origin/main` if `/worktree` is not available.)

### 4. Inject context into the worktree

Write `.claude/CONTEXT.md` inside the worktree with:

```markdown
# Work context — [$ID] $TITLE

**Issue:** $URL
**Branch:** $BRANCH
**Milestone:** MVP Caso 0

## Issue body

<contents of the body field>

## Workflow conventions

- Commit: `<type>(<ID>): <description>` — e.g. `feat(F1-06): persist member tags on join`.
- PR: include `Closes #$ISSUE_NUM` in the body to auto-close on merge.
- Before opening the PR: run `/review` (lint + tests).
- To open the PR: `/done`.

## When to stop

Acceptance criterion lives in the issue body (line **Done:**).
```

### 5. Move the card to "In progress" in the Project

```bash
PROJECT_ID="PVT_kwHOAIgSic4BWXD0"  # Vamos MVP
ITEM_ID=$(gh project item-list 1 --owner julianjab --format json \
  --jq ".items[] | select(.content.number == $ISSUE_NUM) | .id")

STATUS_FIELD_ID=$(gh project field-list 1 --owner julianjab --format json \
  --jq '.fields[] | select(.name=="Status") | .id')

IN_PROGRESS_OPT=$(gh project field-list 1 --owner julianjab --format json \
  --jq '.fields[] | select(.name=="Status") | .options[] | select(.name=="In progress") | .id')

gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
  --field-id "$STATUS_FIELD_ID" --single-select-option-id "$IN_PROGRESS_OPT"
```

If it fails (Status field doesn't exist yet) → log a warning, do not abort. Status auto-assignment can be enabled later in the Project.

### 6. Self-assign the issue (if not already assigned)

```bash
gh issue edit $ISSUE_NUM --repo julianjab/travel-app --add-assignee @me
```

### 7. Report to the user

Print:

```
✓ Picked up issue #$ISSUE_NUM — [$ID] $TITLE
  Branch:   $BRANCH
  Worktree: <path>
  Project:  In progress
  Context:  <path>/.claude/CONTEXT.md

Next step: cd <path> and start working.
When done: /done (auto-infers `Closes #$ISSUE_NUM`).
```

---

## Hard rules

- **Do not touch the main repo.** All work for the issue lives in the worktree.
- **Do not merge from here.** This skill only opens the flow; closing is `/done`'s job + manual merge in GitHub.
- **No branches without an ID.** If the issue has no `[ID]` in its title → abort and ask the user to fix the title first.
- **Do not skip `unset GH_TOKEN GITHUB_TOKEN`** at the start: the env token does not have `project` scope and step 5 will fail.

## When NOT to use /take

- Hotfix without an issue → create the issue first (one-liner, label `mvp`), then `/take`.
- Refactor that touches multiple items → doesn't fit one issue. Use `/worktree init` directly.
- Spike / exploration → `/worktree init spike-<topic>`.
