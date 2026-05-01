---
name: done
description: >
  Close the loop on a Vamos backlog issue. Runs the quality gate (`/review`),
  opens a PR with `Closes #N` auto-inferred from the branch name
  (`<ID>-<slug>`), and moves the Project card to "In review". The actual
  issue close + transition to "Done" is handled by GitHub on merge.
  Triggers: "/done", "I'm done", "open a PR", "ready for review".
  Does NOT auto-merge — merging is a human decision in GitHub.
argument-hint: "[--draft] [--no-review]"
disable-model-invocation: false
---

## /done — Close the loop on the issue

Designed to run **inside the worktree** created by `/take`. Picks the current branch, infers the associated issue, runs the quality gate and opens the PR.

---

## Steps

### 1. Validate context

```bash
unset GH_TOKEN GITHUB_TOKEN
BRANCH=$(git branch --show-current)
```

- If `BRANCH` == `main` → abort. `/done` does not run on main.
- Extract `ID` from the branch name: regex `^([A-Z]+[0-9]*-[0-9]+)-`. E.g. `F1-06-onboarding-miembro` → `F1-06`.
- If it doesn't match → abort and warn: branch does not follow the convention.

### 2. Find the associated issue

```bash
ISSUE_NUM=$(gh issue list --repo julianjab/travel-app --state all \
  --search "[$ID]" --json number,title \
  --jq ".[] | select(.title | startswith(\"[$ID]\")) | .number" | head -1)
```

If not found → abort. The branch must originate from an issue.

### 3. Quality gate

Unless `--no-review` is passed:

```
/review
```

If there are lint, test, or type-check errors → abort and show the user what to fix. Do NOT proceed to the PR.

### 4. Push + open PR

```bash
git push -u origin "$BRANCH"

# Use the issue title as the basis for the PR title
ISSUE_TITLE=$(gh issue view $ISSUE_NUM --repo julianjab/travel-app --json title --jq .title)

PR_BODY=$(cat <<EOF
## Summary

<fill in main changes — 2-3 bullets>

## Issue

Closes #$ISSUE_NUM

## Checklist

- [ ] Tests green (\`flutter test\` or equivalent)
- [ ] Lint clean
- [ ] Issue acceptance criterion met
- [ ] Microcopy reviewed (if applicable)
EOF
)

DRAFT_FLAG=""
if [[ "$ARGUMENTS" == *"--draft"* ]]; then DRAFT_FLAG="--draft"; fi

gh pr create --repo julianjab/travel-app \
  --base main --head "$BRANCH" \
  --title "$ISSUE_TITLE" \
  --body "$PR_BODY" \
  $DRAFT_FLAG
```

### 5. Move the Project card to "In review"

If the Project's `Status` field has an `In review` option:

```bash
ITEM_ID=$(gh project item-list 1 --owner julianjab --format json \
  --jq ".items[] | select(.content.number == $ISSUE_NUM) | .id")
STATUS_FIELD_ID=$(gh project field-list 1 --owner julianjab --format json \
  --jq '.fields[] | select(.name=="Status") | .id')
IN_REVIEW_OPT=$(gh project field-list 1 --owner julianjab --format json \
  --jq '.fields[] | select(.name=="Status") | .options[] | select(.name=="In review") | .id')
[ -n "$IN_REVIEW_OPT" ] && gh project item-edit --id "$ITEM_ID" \
  --project-id "PVT_kwHOAIgSic4BWXD0" \
  --field-id "$STATUS_FIELD_ID" --single-select-option-id "$IN_REVIEW_OPT"
```

If the option doesn't exist → continue, this is not blocking.

### 6. Report

```
✓ PR opened: <URL>
  Branch:   $BRANCH
  Closes:   #$ISSUE_NUM
  Status:   In review

When merged, GitHub will auto-close the issue and the card will move to Done.
```

---

## Hard rules

- **Do not merge from here.** Merging is a human decision in the GitHub UI.
- **Do not skip `/review`** unless explicitly told via `--no-review` (and only for urgent hotfixes).
- **Do not open a PR without an associated issue.** If the branch has no valid ID → abort.
- **`Closes #N`** always goes in the PR body. That is what triggers the auto-close.

## When NOT to use /done

- You only want to push without opening a PR → `git push` directly.
- Work in progress not ready for review → keep working, do not open the PR yet. `--draft` is for PRs already shaped but pending detail.
