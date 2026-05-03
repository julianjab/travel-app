# Vamos — Group travel app for LATAM

## What it is

Vamos is a mobile app to plan and execute group trips, designed from day one for Latin American groups. It turns group trip planning — today fragmented across WhatsApp + Google Docs + Splitwise — into an experience that prevents conflicts instead of generating them.

**Current phase:** MVP Case 0. Single goal: validate that the end-to-end flow doesn't break in a real trip (trip to Brazil, ~6 weeks, founder's own group).

**It is not:** a commercial MVP. No acquisition or revenue metrics. The single metric is: did the group finish the trip using the app from start to end, or did they have to fall back to Splitwise/Wanderlog/Docs at some point?

## Mandatory context

Before any product or code decision, read the relevant docs:

- **`docs/02-prd-inicial.md`** → product principles, personas, in-group role model, priority use cases
- **`docs/03-mvp-scope.md`** → what's in and what's NOT in the MVP, scope decisions made, accepted trade-offs
- **`docs/04-wireframes-mvp-2.md`** → wireframes for the 17 MVP screens, per-screen UX decisions
- **`docs/05-modelo-datos-2.md`** → Firestore data model (collections, fields, security rules, indexes)
- **`docs/06-identidad-y-tono.md`** → name, tone of voice, validated MVP microcopy
- **`docs/01-research-mercado.md`** → market research, gaps, opportunity. Reference, not urgent for day-to-day.

If the question is about Flutter code, also read `app/CLAUDE.md`. If it's about Firestore (rules, indexes, model), also read `firebase/CLAUDE.md`. If it's about the website (Astro, landing, invite page), also read `web/CLAUDE.md`.

## Available agents

They live in `.claude/agents/`. Invoked automatically based on context, or explicitly.

| Agent | Layer | When |
|---|---|---|
| `flutter-builder` | `app/` | Implement screens, widgets, navigation, Riverpod providers. |
| `firestore-architect` | `firebase/` + `app/data/` | Schema, security rules, indexes, Dart repositories. |
| `domain-logic` | `app/lib/*/domain/` | Pure algorithms: balances, debts, splits, conversions, votes. |
| `web-builder` | `web/` | Astro landing, invite page `/j/[code]`, Firebase Hosting deploy. |
| `code-reviewer` | Whole repo | Before any commit or PR — validates layers, naming, tests, money handling. |
| `product-guardian` | — | Before building a new feature or when scope creep appears. |

## Product principles (non-negotiable)

These win when there are hard decisions. Defined in PRD §3.

1. **Prevent conflicts > organize tasks.** Each feature is evaluated against "does this prevent a conflict that happens today?"
2. **Distribute work, don't concentrate it.** The "trip martyr" is the product's enemy.
3. **LATAM-first, not LATAM-translated.** UX, currency, and payment-method decisions are born thinking about Bogotá, CDMX, Buenos Aires.
4. **WhatsApp is an ally, not competition.** Replacing it is losing; integrating is winning.
5. **Works offline or it doesn't work.** Itinerary, documents, and expenses must work without signal. (Note: the MVP partially breaks this principle; see scope §6.)
6. **Simple wins.** Each new feature is evaluated against "does this make the app more usable or more complete?". If it's only "more complete", it's rejected.

## Decisions made (don't reopen without new evidence)

### Stack
- **Frontend (mobile app):** Flutter (iOS + Android, single codebase). Bundle ID `com.jabsolutions.vamos`.
- **Backend:** Firebase (Auth, Firestore, Storage, FCM). No Cloud Functions in MVP.
- **State management:** Riverpod (`AsyncNotifier` / `StreamNotifier`). No ChangeNotifier, no Bloc.
- **Structure:** pragmatic hybrid (features + thin repositories layer that isolates Firestore). No strict clean architecture.
- **Web landing:** Astro (SSG, zero JS by default). Deploy to Firebase Hosting. Serves the invite page (`/j/[code]`) supporting F1.4 and eventually marketing. **Not Flutter web.**

### Product
- **Language:** Spanish only in MVP. Portuguese in v2.
- **Platforms:** mobile app (iOS + Android, Flutter) + web landing (Astro) supporting the invite page (`/j/[code]`) in F1.4 and eventually marketing. No Flutter web.
- **Monetization:** free without restrictions during MVP. Long-term model reopens at month 6 with real data.
- **Roles:** flat model with one facilitator. See PRD §4.4.
- **Sensitive data:** the MVP does NOT handle traveler data at the profile level (national ID, passport, frequent flyer). That goes in v1.1+.

### What's NOT in MVP
Defined explicitly in `docs/03-mvp-scope.md` §4. Summary:
- Trip document vault
- Crisis mode
- Traveler data at profile level
- Pre-trip date coordination
- WhatsApp integration beyond the invite link
- Multi-language
- Flutter web (the mobile app does not compile to web; the landing is a separate Astro project under `web/`, minimal scope in MVP — invite page only)
- Direct booking
- AI / recommendations
- Push notifications (enters v1.1 if feedback asks)
- Real offline sync (same)

If you're asked to implement something from this list, alert the user before moving on: "This is outside MVP scope. Confirm you want to add it anyway?"

## How to work with me (Andrés)

- **Language and tone:** Spanish, voseo, conversational but direct. No formalisms.
- **Stance:** critical, not complacent. If an idea doesn't work, say so with arguments. If there's an important trade-off, put it on the table before implementing.
- **Options:** max 3 alternatives with explicit trade-offs. No lists of 10 equivalent options.
- **Focus:** simple over complete. The product dies from ambition, not from missing features.
- **Don't reopen settled decisions** unless new evidence appears. If a previous conversation closed something, assume it's still in force.
- **Think like a senior product manager** before like a developer. The question is "does this solve a real user problem?" before "how do we build it?".
- **Ask if the question is vague.** But if it's reasonably clear, answer and move on. Don't ask for confirmation on obvious things.
- **Mark anything that only serves my personal case** and doesn't scale to the distributable product.

## Repository structure

```
vamos/
├── CLAUDE.md                       ← this file (global context)
├── README.md                       ← how to run the project
├── app/                            ← Flutter project
│   ├── CLAUDE.md                   ← Flutter code conventions
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
├── firebase/                       ← Firebase infra
│   ├── CLAUDE.md                   ← rules, indexes, model, hosting
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   ├── firebase.json
│   └── functions/                  ← empty until v1.1+
├── web/                            ← web landing (Astro)
│   ├── CLAUDE.md                   ← site conventions
│   ├── src/
│   ├── astro.config.mjs
│   └── package.json
├── docs/                           ← product documentation
│   ├── 01-research-mercado.md
│   ├── 02-prd-inicial.md
│   ├── 03-mvp-scope.md
│   ├── 04-wireframes-mvp-2.md
│   ├── 05-modelo-datos-2.md
│   ├── 06-identidad-y-tono.md
│   └── 07-backlog-v1.1-asistente-ia.md
├── .claude/
│   ├── agents/                     ← per-role agent definitions
│   └── skills/                     ← /take, /done — workflow orchestration
└── .github/
    └── pull_request_template.md    ← PR template with Closes #N
```

## Workflow — backlog, branches, PRs

The backlog is **GitHub-native**. There is no canonical task list in markdown; `docs/08-backlog-mvp.md` is just a pointer.

- **Source of truth:** Issues in `julianjab/travel-app` filtered by milestone `MVP Caso 0`.
- **Project board:** `Vamos MVP` (https://github.com/users/julianjab/projects/1). Status field drives the kanban.
- **Stable IDs** in issue titles: `[E0-02]`, `[F1-06]`, `[F3-07]`, `[X-05]`. Never renumber.

### Per-task flow

1. **Refine the issue:** `/refine <issue-number-or-ID>` — validates scope against MVP, decomposes into a subtask checklist, writes it as `## Plan técnico` in the issue body. Run once per issue. NO code at this stage.
2. **Review the plan in GitHub.** Adjust subtasks if needed. This is the last gate before code.
3. **Pick up the issue:** `/take <issue-number-or-ID>` — creates an isolated worktree, branch `<ID>-<slug>`, moves card to "In progress", spawns a background subagent that implements the plan. Each subtask becomes one commit; the agent marks `[x]` in the issue body as it goes.
4. **Open the PR:** `/done` — runs `/review` (lint + tests), pushes branch, opens PR with `Closes #N` autoinferred from the branch name. Card moves to "In review".
5. **Merge from GitHub UI.** GitHub auto-closes the issue (via `Closes #N`) and the Project workflow moves the card to "Done".

### Hard rules

- **No work on `main`.** Always via worktree + PR. Even one-line changes.
- **No issue without an `[ID]` in the title.** Agents abort if they can't parse one.
- **No PR without `Closes #N`.** That's what wires the issue → PR → card → done chain. The PR template enforces it.
- **Adding a new item:** create an issue in `julianjab/travel-app` with `[<ID>]` in title, labels `mvp` + `epic:<flow>`, milestone `MVP Caso 0`, assigned to the Project. See conventions in `docs/08-backlog-mvp.md`.
- **Out-of-scope work** (anything in `docs/03-mvp-scope.md` §4): do NOT use label `mvp`. Goes to a future milestone or stays as `epic:cross` follow-up.

### Skills

Defined under `.claude/skills/`:

- `/refine <issue>` — technical refinement: scope check + subtask checklist into the issue body. Required before `/take`.
- `/take <issue>` — start working an issue (worktree + context + background implementer that ticks off subtasks).
- `/done` — close the loop (review + push + PR with `Closes #N`).
- `/autopilot` — fully autonomous pipeline: processes every Todo issue sequentially (refine → implement → PR → merge → next) without human gates. Designed for solo preliminary dev where no one else is affected. Flags: `--from <id>`, `--only <id>`, `--dry-run`.

Both depend on `gh` having `project` scope. Token lives in `~/.profile` (`GH_TOKEN` / `GITHUB_TOKEN`). If commands fail with `missing scope` or `HTTP 401`, rotate the PAT at https://github.com/settings/tokens with scopes `repo` + `project` and update `~/.profile`.

## Language conventions

- **CLAUDE.md files, agent definitions, code comments, commit messages, tests, technical docs:** English.
- **User-facing microcopy in the app and web (strings shown to the user):** Spanish, voseo. Validated copy lives in `docs/06-identidad-y-tono.md`.
- **Product docs under `docs/`:** Spanish. They are decision records, not technical artifacts.
