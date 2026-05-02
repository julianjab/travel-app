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
argument-hint: "<issue-number-or-ID> [--base main] [--foreground] [--no-implement] [--skip-plan]"
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

### 2.b. Require a refined plan

Check that the body contains a `## Plan técnico` section:

```bash
HAS_PLAN=$(jq -r '.body' /tmp/take-issue.json | grep -c '^## Plan técnico' || true)
```

If `HAS_PLAN == 0` → abort with:

```
✗ Issue #$ISSUE_NUM has no technical plan.
  Run `/refine $ISSUE_NUM` first, review the plan in GitHub, then `/take` again.
```

The plan is non-negotiable: implementers receive subtasks as a checklist they must mark `[x]` as they commit, and the plan is the agreed contract on scope.

Skip this check only when called as `/take $ISSUE_NUM --skip-plan` (use sparingly, only for trivial fixes).

### 3. Create the worktree

Reuse the existing skill:

```
/worktree init $BRANCH --base main
```

(Or run directly with `git worktree add .worktrees/$BRANCH -b $BRANCH origin/main` if `/worktree` is not available. Worktrees live under `.worktrees/` inside the main repo, matching the `ia-tools/skills/worktree` convention. The folder is gitignored.)

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

### 7. Report setup

Print:

```
✓ Picked up issue #$ISSUE_NUM — [$ID] $TITLE
  Branch:   $BRANCH
  Worktree: <path>
  Project:  In progress
  Context:  <path>/.claude/CONTEXT.md
```

### 8. Hand off to implementation

Three modes:

| Flag | Behavior |
|---|---|
| _(default)_ | Spawn a **background subagent** that implements the issue while the main session stays free. |
| `--foreground` | The current session continues working in the worktree directly. |
| `--no-implement` | Stop after step 7. The user takes over manually. |

#### Default — background subagent

Pick the right subagent based on the epic label:

| Label | `subagent_type` |
|---|---|
| `epic:setup` | `general-purpose` |
| `epic:F1`, `epic:F2` | `flutter-builder` (UI) or `firestore-architect` (data) — read body to choose |
| `epic:F3` | `domain-logic` (algorithm) or `flutter-builder` (UI) — read body |
| `epic:cross` | depends on body |

Spawn with the `Agent` tool, `run_in_background: true`. The prompt must be self-contained because the subagent does NOT see this conversation. Template:

```
You are implementing GitHub issue #<ISSUE_NUM> for julianjab/travel-app.

## Working directory
Absolute path: <WORKTREE_PATH>
Branch: <BRANCH>
ALL work happens here. Do not touch the main repo.

## Your task
<full body of the issue, copied verbatim — this includes the `## Plan técnico` section with the subtask checklist>

## Subtask discipline
The issue body has a `## Plan técnico` section with subtasks formatted as
GitHub checkboxes (`- [ ] ...`). For EACH subtask:
1. Implement it as one focused commit.
2. After the commit, mark the box as `[x]` by editing the issue body via `gh issue edit`.
3. Move to the next.

This gives humans real-time visibility into progress without opening Claude.

## Context
1. Read <WORKTREE_PATH>/.claude/CONTEXT.md first.
2. Read the project root CLAUDE.md and the relevant area CLAUDE.md (app/, firebase/, or web/).
3. If the issue references a wireframe (Fx.y), read docs/04-wireframes-mvp-2.md.
4. If it touches the data model, read docs/05-modelo-datos-2.md AND firebase/CLAUDE.md.

## Workflow
- Validate scope against docs/03-mvp-scope.md before writing code. If something
  smells out of scope, STOP and report — do not expand.
- Commit in small steps: `<type>(<ID>): <description>` (Conventional Commits + ID).
- Acceptance criterion is the line starting with **Done:** in the issue body.

## When the Done criterion is covered
- Run lint + tests for the area you touched (`flutter analyze && flutter test`,
  or `pnpm lint && pnpm typecheck` for web).
- Push the branch: `git push -u origin <BRANCH>`.
- Open a PR with `gh pr create`:
    --base main --head <BRANCH>
    --title "<issue title>"
    --body "Closes #<ISSUE_NUM>\n\n<summary>\n\n<checklist>"
    --draft   (always draft — human reviews and marks ready)

## Hard limits
- Never push to main.
- Never merge the PR.
- Never use `--no-verify` or skip hooks.
- Never modify files outside the worktree.
- If you get stuck, write what you tried in the PR description and exit.

Report back: PR URL + summary of changes + anything skipped or flagged.
```

After spawning, print:

```
✓ Background agent started on #$ISSUE_NUM
  Subagent: <type>
  Worktree: <path>
  You can keep working. You'll be notified when the agent finishes.
```

#### `--foreground`

Same prompt structure, but the current session continues directly: `cd` to worktree, read CONTEXT.md, implement, run `/done`. Use this when you want to drive the implementation interactively.

#### `--no-implement`

Stop after step 7 with: "Setup done. Run `/take <id>` (default) to spawn a background agent, or `/take <id> --foreground` to work in this session."

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
