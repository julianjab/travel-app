#!/usr/bin/env node
// X-11 — Backfill `memberAliases` on existing trip docs.
//
// Reads every `trips/*` document, joins it with `trips/{tripId}/members/*`
// and writes the denormalized `memberAliases: { uid -> alias }` map to the
// parent doc. Idempotent: trips that already have a complete map (one entry
// per uid in memberIds) are skipped.
//
// Usage (against the prod Firestore project linked in `firebase use`):
//
//   cd firebase
//   GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json \
//     node scripts/migrate_member_aliases.mjs
//
// Add `--dry-run` to print the diff without writing.
//
// The MVP only has the founder's Brasil/Rio test trip in production, so this
// is small-scale: the script is here to make the migration repeatable rather
// than to scale.

import admin from "firebase-admin";

const dryRun = process.argv.includes("--dry-run");

admin.initializeApp({
  // Uses ADC from GOOGLE_APPLICATION_CREDENTIALS or the gcloud login.
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function main() {
  const tripsSnap = await db.collection("trips").get();
  console.log(`Found ${tripsSnap.size} trip(s).`);

  let updated = 0;
  let skipped = 0;

  for (const tripDoc of tripsSnap.docs) {
    const data = tripDoc.data();
    const memberIds = Array.isArray(data.memberIds) ? data.memberIds : [];
    const existingAliases =
      data.memberAliases && typeof data.memberAliases === "object"
        ? data.memberAliases
        : {};

    // Already complete? Skip.
    const allPresent = memberIds.every((uid) => typeof existingAliases[uid] === "string");
    if (allPresent && Object.keys(existingAliases).length === memberIds.length) {
      skipped += 1;
      continue;
    }

    // Build a fresh map from the members subcollection.
    const membersSnap = await tripDoc.ref.collection("members").get();
    const aliases = {};
    for (const m of membersSnap.docs) {
      const alias = m.data().alias;
      if (typeof alias === "string" && alias.trim().length > 0) {
        aliases[m.id] = alias;
      }
    }

    // Fall back to the existing map for any missing uid (so we never overwrite
    // a value with a worse one).
    for (const [uid, alias] of Object.entries(existingAliases)) {
      if (!(uid in aliases) && typeof alias === "string") {
        aliases[uid] = alias;
      }
    }

    // Final sanity check: invariant size match.
    const missing = memberIds.filter((uid) => !(uid in aliases));
    if (missing.length > 0) {
      console.warn(
        `! trip ${tripDoc.id}: missing alias for ${missing.join(", ")}; ` +
          `using uid as placeholder so the rule invariant holds.`,
      );
      for (const uid of missing) aliases[uid] = uid;
    }

    if (dryRun) {
      console.log(`~ [dry-run] ${tripDoc.id}: would set memberAliases=`, aliases);
    } else {
      await tripDoc.ref.update({ memberAliases: aliases });
      console.log(`+ ${tripDoc.id}: memberAliases set with ${Object.keys(aliases).length} entries.`);
    }
    updated += 1;
  }

  console.log(`Done. updated=${updated} skipped=${skipped} (dryRun=${dryRun}).`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
