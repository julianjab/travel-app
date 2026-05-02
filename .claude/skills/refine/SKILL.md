---
name: refine
description: >
  Technical refinement of a Vamos backlog issue. Reads the issue body and linked
  docs, validates scope against the MVP, decomposes the work into a concrete
  task checklist, and writes the result into the issue body as a "Plan técnico"
  section. Does NOT touch code — this is the planning gate before /take.
  Triggers: "/refine 14", "/refine F3-01", "refinar la 14", "armá el plan
  técnico para F3-01". Run this once per issue, before /take.
argument-hint: "<issue-number-or-ID> [--force]"
disable-model-invocation: false
---

## /refine — Technical refinement of an issue

Turns a backlog issue from "title + acceptance criterion" into "actionable plan with subtasks". The plan lives in the issue body so the implementer (and humans) consume the same source of truth.

**Repo:** `julianjab/travel-app`
**Project:** `Vamos MVP` (#1, owner `julianjab`)

---

## Arguments

| Form | Example | Behavior |
|---|---|---|
| Issue number | `14` | Refine issue #14 |
| Backlog ID | `F3-01` | Find issue with title starting `[F3-01]` |
| `--force` | `14 --force` | Re-refine even if a `## Plan técnico` section already exists (replaces it) |

---

## Steps

### 1. Resolve the issue

Same resolver as `/take`: number → direct lookup; ID → search by title prefix.

### 2. Idempotency check

```bash
EXISTING=$(gh issue view $ISSUE_NUM --repo julianjab/travel-app --json body \
  --jq '.body' | grep -c "^## Plan técnico" || true)
```

If `EXISTING > 0` and `--force` is not passed → abort with: "Issue already refined. Pass `--force` to redo."

### 3. Load context

Read in this order:
1. The issue body (current).
2. `CLAUDE.md` (root) — workflow + scope principles.
3. `docs/03-mvp-scope.md` — what's in / out.
4. The wireframe section referenced in the body (`docs/04-wireframes-mvp-2.md` Fx.y) if applicable.
5. `docs/05-modelo-datos-2.md` if the issue touches the data model.
6. The area `CLAUDE.md` (`app/`, `firebase/`, or `web/`) based on the epic label.

### 4. Scope validation (mandatory)

Use the `product-guardian` subagent. Prompt:

```
Validate that issue #<ISSUE_NUM> stays within MVP Caso 0 scope.

Issue body:
<body>

Read docs/03-mvp-scope.md §4 (out of scope list) and §5 (closed decisions).

Return ONE of:
- "IN_SCOPE" + 1 sentence on why.
- "OUT_OF_SCOPE: <reason>" + which §4 entry it matches.
- "AMBIGUOUS: <question>" if the issue body is unclear about scope.
```

If `OUT_OF_SCOPE` → abort, post a comment on the issue with the reason, and tell the user to either close the issue or move it to a future milestone.

If `AMBIGUOUS` → abort, post the question as a comment, tell the user to clarify the body.

If `IN_SCOPE` → continue.

### 5. Decompose into a plan

Pick the right specialist subagent based on the epic label:

| Label | Subagent for refinement |
|---|---|
| `epic:setup` | `general-purpose` |
| `epic:F1`, `epic:F2` | `flutter-builder` (UI) + `firestore-architect` (if model touched) |
| `epic:F3` | `domain-logic` (algorithm) + `flutter-builder` (UI) |
| `epic:cross` | depends on body |

Prompt template:

```
Refine the technical plan for issue #<ISSUE_NUM>.

Context:
- Issue body: <body>
- Linked docs already loaded.
- DO NOT write code. Only the plan.

Produce a markdown section called "## Plan técnico" with EXACTLY this shape and nothing else:

### Subtareas
- [ ] <one commit of work> (`<file/path>`)
- [ ] ...
(3 to 7 items. Each names the concrete file or function. Each is verifiable.)

### No hacer
- <thing the implementer might be tempted to do but is out of scope>
(1 to 3 bullets max. Reference the owning issue ID if applicable, e.g. "es F2-01".)

### Notas
- <gotchas, dependencies, or decisions the implementer can't make alone>
(0 to 3 bullets. Skip the section if there are no notes.)

Hard limits:
- Total length under 25 lines.
- No prose paragraphs.
- No "files to touch" section: file paths live INSIDE the subtasks.
- No "verification" section: the issue body already has **Done:**.
- No fluff like "this is important" or "be careful".
```

### 6. Write the plan into the issue body

```bash
CURRENT_BODY=$(gh issue view $ISSUE_NUM --repo julianjab/travel-app --json body --jq '.body')

# If --force and existing plan: strip the old "## Plan técnico" section first.
# Otherwise: append.

NEW_BODY="$CURRENT_BODY

---

## Plan técnico

_$(date -u +%Y-%m-%d) · scope: IN_SCOPE_

<plan generated in step 5>
"

gh issue edit $ISSUE_NUM --repo julianjab/travel-app --body "$NEW_BODY"
```

### 7. Comment for traceability

```bash
gh issue comment $ISSUE_NUM --repo julianjab/travel-app --body \
"🧠 Refinado: <N> subtareas. Revisá el plan en el body antes de \`/take\`."
```

### 8. (Optional) Move Project status to "Ready"

If the Project's `Status` field has a `Ready` option (between `Todo` and `In progress`), move the card there. If not, no-op.

### 9. Report

```
✓ Refined issue #$ISSUE_NUM — [$ID] $TITLE
  Plan: <N> subtasks
  Body updated: <issue URL>
  Scope check: IN_SCOPE

Next step: review the plan in GitHub. When ready: /take $ISSUE_NUM
```

---

## Hard rules

- **No code.** This skill plans only. If the implementing subagent feels the urge to write code, it must stop and report the urge as a comment.
- **No silent scope expansion.** If `product-guardian` flags ambiguity, abort. Don't guess.
- **Plan lives in the issue body, not in a side file.** GitHub is source of truth.
- **One plan per issue.** Re-refinement requires `--force` and replaces the section, not appends.

## Contract with /take

`/take` reads `## Plan técnico` from the issue body and:

1. If missing → abort with: "Run /refine $ISSUE_NUM first."
2. If present → injects subtasks into the implementer's prompt as a checklist.
3. The implementer marks each subtask `[x]` in the issue body as it commits, via `gh issue edit`.

This wires "issue body = single source of truth for plan + progress".

## When NOT to use /refine

- Trivial fixes (typo, lint) — too much overhead. Just `/take` directly.
- Spike / exploration — there's no plan to refine; the work IS the plan.
- Issue body is already a hand-written detailed plan you wrote on purpose.
