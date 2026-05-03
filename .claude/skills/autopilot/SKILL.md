---
name: autopilot
description: >
  Fully autonomous pipeline that works through the entire Vamos MVP backlog
  without human intervention. For each issue in Todo: refines the plan, creates
  a worktree, implements, opens a PR, merges it, pulls main, and moves to the
  next. Designed for preliminary solo development where no one else is affected.
  Triggers: "/autopilot", "trabajá el backlog", "procesar todos los issues",
  "modo autónomo". Does NOT ask for confirmation between issues.
argument-hint: "[--from <issue-number-or-ID>] [--only <issue-number-or-ID>] [--dry-run]"
disable-model-invocation: false
---

## /autopilot — Full autonomous backlog pipeline

Processes every open MVP issue in Todo status, sequentially, without human gates.
Each issue goes through: **refine → worktree → implement → PR → merge → cleanup → next**.

**Repo:** `julianjab/travel-app`
**Project:** `Vamos MVP` (#1, owner `julianjab`)

---

## Arguments

| Flag | Example | Behavior |
|---|---|---|
| _(none)_ | `/autopilot` | Process all Todo issues with label `mvp`, in issue-number order |
| `--from <id>` | `--from F2-01` | Skip issues before this one (resume after a partial run) |
| `--only <id>` | `--only 14` | Process a single issue through the full pipeline |
| `--dry-run` | `--dry-run` | Print the queue without executing anything |

---

## Pre-flight checks

Before processing any issue, verify:

```bash
# 1. Must be on main branch and clean
git status --porcelain | grep -q . && echo "DIRTY" || echo "CLEAN"
git branch --show-current  # must be main

# 2. gh must be authenticated with project scope
gh auth status

# 3. No open worktrees from a previous interrupted run
git worktree list

# 4. main is up-to-date with origin
git fetch origin main && git status -uno
```

If the working tree is dirty or not on main → abort. Tell the user to stash or commit first.
If there are leftover worktrees → list them and ask whether to clean up before proceeding.

---

## Build the queue

```bash
gh issue list \
  --repo julianjab/travel-app \
  --state open \
  --label mvp \
  --milestone "MVP Caso 0" \
  --json number,title,labels \
  --jq 'sort_by(.number) | .[] | "\(.number)\t\(.title)"'
```

Filter to issues whose Project card Status == "Todo". If `--from` is given, drop all issues before that ID. If `--only` is given, keep only that issue.

Print the queue:

```
Autopilot queue — N issues
  #14  [F1-06] Onboarding miembro
  #17  [F2-01] Pantalla itinerario
  ...

Starting in 3 seconds. Ctrl-C to abort.
```

Wait 3 seconds (not configurable), then begin.

---

## Per-issue pipeline

For each issue `ISSUE_NUM` in the queue:

### Step 1 — Announce

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[N/TOTAL] #$ISSUE_NUM — $TITLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 2 — Ensure main is up to date

```bash
git fetch origin main
git merge --ff-only origin/main
```

If fast-forward fails → abort the entire pipeline with a conflict warning.

### Step 3 — Refine (if no plan exists)

```bash
HAS_PLAN=$(gh issue view $ISSUE_NUM --repo julianjab/travel-app \
  --json body --jq '.body' | grep -c "^## Plan técnico" || true)
```

- If `HAS_PLAN == 0`: run the full `/refine $ISSUE_NUM` flow inline (do not spawn a subagent — run it in this session so errors surface immediately).
- If `HAS_PLAN > 0`: skip refine, reuse existing plan.

If `/refine` aborts (OUT_OF_SCOPE or AMBIGUOUS) → log the issue as SKIPPED with the reason, continue to the next issue. Do NOT abort the entire pipeline.

### Step 4 — Create worktree

Extract `ID` and `BRANCH` from the issue title (same logic as `/take`):

```bash
TITLE=$(gh issue view $ISSUE_NUM --repo julianjab/travel-app --json title --jq .title)
ID=$(echo "$TITLE" | grep -oE '\[[A-Z0-9-]+\]' | head -1 | tr -d '[]')
SLUG=$(echo "$TITLE" | sed 's/\[[^]]*\]//g' | tr '[:upper:]' '[:lower:]' \
  | iconv -f utf-8 -t ascii//TRANSLIT \
  | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//' | cut -c1-40)
BRANCH="$ID-$SLUG"
WORKTREE=".worktrees/$BRANCH"

git worktree add "$WORKTREE" -b "$BRANCH" origin/main
```

### Step 5 — Inject context

Write `.claude/CONTEXT.md` inside the worktree (same format as `/take` step 4):

```markdown
# Work context — [$ID] $TITLE

**Issue:** $URL
**Branch:** $BRANCH
**Milestone:** MVP Caso 0
**Autopilot:** true — no human review gate, merge will happen automatically.

## Issue body

<contents of the body field>

## Workflow conventions

- Commit: `<type>(<ID>): <description>` — e.g. `feat(F1-06): persist member tags on join`.
- PR: include `Closes #$ISSUE_NUM` in the body to auto-close on merge.
- Lint and tests must pass before pushing — autopilot will merge the PR without human review.

## When to stop

Acceptance criterion lives in the issue body (line **Done:**).
```

### Step 6 — Move Project card to "In progress"

```bash
PROJECT_ID="PVT_kwHOAIgSic4BWXD0"
ITEM_ID=$(gh project item-list 1 --owner julianjab --format json \
  --jq ".items[] | select(.content.number == $ISSUE_NUM) | .id")
STATUS_FIELD_ID=$(gh project field-list 1 --owner julianjab --format json \
  --jq '.fields[] | select(.name=="Status") | .id')
IN_PROGRESS_OPT=$(gh project field-list 1 --owner julianjab --format json \
  --jq '.fields[] | select(.name=="Status") | .options[] | select(.name=="In progress") | .id')
gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
  --field-id "$STATUS_FIELD_ID" --single-select-option-id "$IN_PROGRESS_OPT"
```

### Step 7 — Implement (foreground, inline)

Pick the right specialist subagent based on the epic label (same table as `/take`), but spawn it **in the foreground** (not background) so this pipeline waits for it to finish.

Subagent prompt — same template as `/take` step 8, with these additions:

```
## Autopilot mode

This issue is part of a fully automated pipeline. After you finish:
1. Run lint + tests.
2. Push the branch.
3. Do NOT open the PR — autopilot handles that.
4. Exit cleanly so the pipeline can continue.

Do NOT open a PR. Do NOT merge. Just implement, commit, push, and exit.
```

Wait for the subagent to finish. If it reports failure or exits with uncommitted work → mark issue as FAILED, clean up worktree, continue to next issue.

### Step 8 — Quality gate

From inside the worktree, run:

```bash
cd "$WORKTREE"
flutter analyze && flutter test   # if epic:F1, F2, F3
# or
pnpm lint && pnpm typecheck       # if epic:web
```

If errors → mark issue as FAILED, clean up worktree, log the error, continue.

### Step 9 — Push + open PR

```bash
cd "$WORKTREE"
git push -u origin "$BRANCH"

ISSUE_TITLE=$(gh issue view $ISSUE_NUM --repo julianjab/travel-app --json title --jq .title)

gh pr create --repo julianjab/travel-app \
  --base main --head "$BRANCH" \
  --title "$ISSUE_TITLE" \
  --body "$(cat <<EOF
## Summary

Automated implementation via /autopilot.

## Issue

Closes #$ISSUE_NUM

## Checklist

- [x] Tests green
- [x] Lint clean
- [x] Acceptance criterion met
EOF
)"
```

### Step 10 — Merge the PR

```bash
PR_NUM=$(gh pr list --repo julianjab/travel-app --head "$BRANCH" \
  --json number --jq '.[0].number')

gh pr merge "$PR_NUM" --repo julianjab/travel-app --merge --delete-branch
```

Wait for merge to complete:

```bash
until gh pr view "$PR_NUM" --repo julianjab/travel-app --json state \
  --jq '.state' | grep -q "MERGED"; do sleep 2; done
```

### Step 11 — Move Project card to "Done"

```bash
DONE_OPT=$(gh project field-list 1 --owner julianjab --format json \
  --jq '.fields[] | select(.name=="Status") | .options[] | select(.name=="Done") | .id')
gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
  --field-id "$STATUS_FIELD_ID" --single-select-option-id "$DONE_OPT"
```

### Step 12 — Cleanup

```bash
# Remove the worktree (branch was deleted by --delete-branch in merge)
git worktree remove "$WORKTREE" --force
```

### Step 13 — Issue summary

```
✓ #$ISSUE_NUM [$ID] done
  PR:     #$PR_NUM (merged)
  Branch: $BRANCH (deleted)
  Time:   <elapsed>
```

---

## Final report

After processing the entire queue:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Autopilot complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Done:    N issues merged to main
  Skipped: N (out of scope / no plan)
  Failed:  N (lint errors / subagent failure)

Failed issues:
  #14  [F1-06] — lint error in auth_provider.dart
  ...

Skipped issues:
  #22  [X-03] — OUT_OF_SCOPE: push notifications are v1.1+
  ...
```

---

## Error handling rules

| Situation | Action |
|---|---|
| `/refine` returns OUT_OF_SCOPE | Skip issue, log it, continue |
| `/refine` returns AMBIGUOUS | Skip issue, post question as GitHub comment, continue |
| Subagent fails or times out | Mark FAILED, remove worktree, continue |
| Lint / tests fail | Mark FAILED, leave branch as-is for inspection, continue |
| PR merge fails (conflict) | Mark FAILED, leave PR open, continue |
| `git merge --ff-only` fails at step 2 | ABORT entire pipeline — main has diverged |
| No issues in queue | Print "Queue is empty. Backlog complete." and exit |

Never abort the entire pipeline for a single-issue failure, except for the `git merge --ff-only` case (that means main is in a bad state).

---

## Hard rules

- **Never push to main directly.** Always via PR.
- **Never skip lint + tests** (step 8). Autopilot merging broken code defeats the purpose.
- **Never modify files outside the worktree** during implementation.
- **Never reopen a scope decision.** If `product-guardian` flags OUT_OF_SCOPE, skip — do not negotiate.
- **Sequential only.** Do not process two issues in parallel in autopilot mode. Race conditions on main are not worth the speed gain.

## When NOT to use /autopilot

- There are other contributors on the repo — review is a quality gate, not ceremony.
- You need to verify UX/behavior manually before merging.
- The backlog has issues that depend on each other in a non-obvious order.
