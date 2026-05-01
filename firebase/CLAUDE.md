# Firebase — Rules, indexes, and model

> This file applies to everything under `firebase/`. Assume the root `CLAUDE.md` has already been read.

## Data model

**Single source of truth:** `docs/05-modelo-datos-2.md`.

Any change to the model (new field, new collection, type change) requires:

1. Update `docs/05-modelo-datos-2.md` §2.2 first.
2. Update the corresponding Dart model in `app/lib/data/models/`.
3. If the field affects security rules, update `firestore.rules`.
4. If it requires a new index, add it to `firestore.indexes.json`.

The order matters: doc first. If the doc isn't updated, in 3 months no one will remember why a field is there.

## Folder structure

```
firebase/
├── CLAUDE.md                ← this file
├── firebase.json            ← Firebase project config
├── .firebaserc              ← project alias (dev / prod)
├── firestore.rules          ← security rules
├── firestore.indexes.json   ← composite indexes
├── storage.rules            ← Firebase Storage rules (receipt photos, covers)
└── functions/               ← EMPTY UNTIL v1.1+
```

## Security rules

The base scaffold lives in `docs/05-modelo-datos-2.md` §4. **It is scaffold, not production-ready.** Missing:

- Type validation (`request.resource.data.amount is number`)
- Size limits (string max N characters)
- Required-field validation on `create`
- Spam prevention on `invites` (rate limiting)
- Field immutability validation (e.g., `createdBy` cannot be changed after create)

When the production-ready version of the rules is closed, it lives in `firestore.rules` and is documented in a separate file (`docs/07-firestore-rules.md` is reserved for this).

### General rules pattern

- **Only trip members read/write its subcollections.** Validated with `request.auth.uid in get(/databases/$(database)/documents/trips/$(tripId)).data.memberIds`.
- **Each `get(...)` counts as an extra read.** It's pennies in Case 0 but keep it in mind for scale.
- **`memberIds` is a denormalized array** in the trip doc. This exists because Firestore doesn't allow rules with joins. Any membership change must update both the array AND the `members/` subcollection.

### Specific non-obvious rules

- **`expenses.update`:** any trip member can edit any expense, **except if `hasSettlements == true`**. Each edit is logged in `editHistory`. Decision 3.6 of the data model.
- **`expenses.delete`:** only the creator, and only if `hasSettlements == false`. Deleting is destructive (history goes with the expense).
- **`items.delete`:** item author OR trip facilitator.
- **`trips`:** no `delete`. Only `archive` (change `status` to `"archived"`).
- **`invites`:** public read by design (anyone with the link can see the `tripId`). `create` is for authenticated users only.

## Indexes

Simple indexes are auto-created by Firestore. Composite ones must be declared in `firestore.indexes.json`. The MVP ones are listed in `docs/05-modelo-datos-2.md` §5:

- `items` by `(day asc, createdAt asc)` — daily itinerary view
- `expenses` by `(date desc, createdAt desc)` — reverse chronological list
- `trips` by `(memberIds array-contains, status, startDate desc)` — "My trips" home

If a new query requires an index, Firestore says so at runtime with a direct creation link. When it shows up, add it to the JSON and commit; don't create it from the console alone, that leaves it out of version control.

## Cloud Functions

**Not used in MVP.** Closed decision in `docs/05-modelo-datos-2.md` §3.4.

The `functions/` folder exists empty as a placeholder for v1.1+. Cases where they could enter:

- **Push notifications** (FCM dispatch on vote / new expense)
- **Automatic cleanup** of archived trips (delete Storage docs after N months)
- **Unique `inviteCode` generation** (if collisions, though with 6+ random chars the probability is negligible for Case 0)

If you're asked to add a Cloud Function, alert first: "This means going outside MVP scope. Confirm?"

## Storage (Firebase Storage)

Used for:

- **Trip cover photos** (`coverPhotoURL` in `trips/{tripId}`)
- **User profile photos** (`photoURL` in `users/{userId}`)
- **Expense receipt photos** (`photoURL` in `trips/{tripId}/expenses/{expenseId}`)

### Storage rules

Pattern equivalent to Firestore: only trip members read/write that trip's photos. Profile photo is public read, write only by the user themselves.

Concrete rules are written when implementing the first flow that uploads photos (likely F1.2 with the cover photo).

## Hosting (web landing)

Firebase Hosting serves the Astro landing (`web/`). The build is generated with `astro build` (static output) and deployed with `firebase deploy --only hosting`.

The config in `firebase.json` points to `../web/dist` as the `public` directory. Dynamic routes (`/j/[code]`) are handled client-side: Astro generates static HTML and a script that fetches the trip from Firestore using the web SDK.

### Why Firebase Hosting and not CloudFront

- Already in the stack — single Firebase project, single billing account.
- Free up to 10GB/month of transfer, enough for Case 0 + Cases 1-5.
- Global CDN included and custom domains free.
- Native integration with auth and Firestore rules.
- CloudFront would only make sense if there were already AWS infra for another reason, which is not the case.

### Deploy

```
cd web/
pnpm build              # generates dist/
cd ../firebase/
firebase deploy --only hosting
```

### Hosting rules

- Don't serve dynamic content requiring SSR. Astro is configured in `static` mode.
- Don't replicate mobile app functionality on the landing (auth with persistent session, expense editing, etc.). The landing is **read-only** over `invites/{inviteCode}` and `trips/{tripId}` (minimal projection); any write goes through the mobile app.
- Don't add redirects/rewrites configurations without updating this doc.

## How to add a field to a collection — checklist

So nothing is forgotten:

1. Update `docs/05-modelo-datos-2.md` §2.2 with the new field (type, default, optional/required)
2. Update the Dart model in `app/lib/data/models/<collection>_model.dart`
3. Update the repository in `app/lib/data/repositories/<collection>_repository.dart` to serialize/deserialize the field
4. If the field is required in `create`, update the `create` rule in `firestore.rules`
5. If the field affects queries, evaluate if it needs an index in `firestore.indexes.json`
6. If the field is sensitive (privacy), document in PRD §4.5 or equivalent
7. If the app has production data, plan migration (in MVP this doesn't apply yet)

## What NOT to do

- Don't add fields to the model without updating the data model doc first.
- Don't disable rules to "test fast" in production. To test, use the local Firebase emulator.
- Don't use the Firebase console to create indexes outside version control.
- Don't add Cloud Functions without discussing the case.
- Don't add new collections (notifications, logs, extra audit trail) — see `docs/05-modelo-datos-2.md` §6 for what's deliberately out.

## Comments in `.rules` and config files

All inline comments in `firestore.rules`, `storage.rules`, and config JSONs are written in English.

## Quick references

- Full data model: `docs/05-modelo-datos-2.md`
- PRD §4.5 (sensitive data): `docs/02-prd-inicial.md`
- Scope (what's NOT in MVP): `docs/03-mvp-scope.md` §4
