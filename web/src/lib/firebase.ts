// firebase.ts — Firebase JS SDK initialization and invite-resolution helper.
// Only imports `app` and `firestore` modules. No auth, no storage.
// These are public client-side keys — safe to commit for MVP.

import { initializeApp, getApps, type FirebaseApp } from 'firebase/app';
import {
  getFirestore,
  doc,
  getDoc,
  type Firestore,
  type Timestamp,
} from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyD6mhVJREzmdmGzLMqAiAd4OT8wy4S857U',
  authDomain: 'vamos-app-a5f24.firebaseapp.com',
  projectId: 'vamos-app-a5f24',
  storageBucket: 'vamos-app-a5f24.firebasestorage.app',
  messagingSenderId: '142817827453',
  appId: '1:142817827453:web:1044cf3b628ecf98b2af14',
};

// Prevent duplicate initialization in hot-reload environments
let app: FirebaseApp;
let db: Firestore;

function getFirebaseApp(): FirebaseApp {
  if (getApps().length === 0) {
    app = initializeApp(firebaseConfig);
  } else {
    app = getApps()[0]!;
  }
  return app;
}

function getDb(): Firestore {
  if (!db) {
    db = getFirestore(getFirebaseApp());
  }
  return db;
}

// --- Types matching docs/05-modelo-datos-2.md §2.2 ---

export interface InviteDoc {
  tripId: string;
  createdBy: string;
  createdAt: Timestamp;
  active: boolean;
}

/** Minimal trip projection used only to render the invite page. */
export interface TripProjection {
  name: string;
  destination: string;
  startDate: Timestamp;
  endDate: Timestamp;
  facilitatorId: string;
  status: string;
}

export interface ResolvedInvite {
  invite: InviteDoc;
  trip: TripProjection;
}

export type InviteError = 'not_found' | 'revoked' | 'trip_not_found';

export type InviteResult =
  | { ok: true; data: ResolvedInvite }
  | { ok: false; error: InviteError };

/**
 * Resolves an invite code to its trip data.
 * Reads `invites/{code}` then `trips/{tripId}` (minimal projection).
 * Never writes to Firestore.
 */
export async function resolveInvite(code: string): Promise<InviteResult> {
  const firestore = getDb();

  // 1. Read the invite document
  const inviteRef = doc(firestore, 'invites', code);
  const inviteSnap = await getDoc(inviteRef);

  if (!inviteSnap.exists()) {
    return { ok: false, error: 'not_found' };
  }

  const invite = inviteSnap.data() as InviteDoc;

  if (!invite.active) {
    return { ok: false, error: 'revoked' };
  }

  // 2. Read the trip (minimal projection)
  const tripRef = doc(firestore, 'trips', invite.tripId);
  const tripSnap = await getDoc(tripRef);

  if (!tripSnap.exists()) {
    return { ok: false, error: 'trip_not_found' };
  }

  const trip = tripSnap.data() as TripProjection;

  return { ok: true, data: { invite, trip } };
}

/**
 * Formats a Firestore Timestamp pair as "12 jun – 5 jul 2026".
 * Month names are in Spanish, lowercase.
 */
export function formatDateRange(start: Timestamp, end: Timestamp): string {
  const startDate = start.toDate();
  const endDate = end.toDate();

  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  const startDay = startDate.getDate();
  const startMonth = months[startDate.getMonth()];
  const endDay = endDate.getDate();
  const endMonth = months[endDate.getMonth()];
  const endYear = endDate.getFullYear();

  if (startDate.getMonth() === endDate.getMonth() && startDate.getFullYear() === endDate.getFullYear()) {
    // Same month: "12 – 25 jun 2026"
    return `${startDay} – ${endDay} ${endMonth} ${endYear}`;
  }

  // Different months: "12 jun – 5 jul 2026"
  return `${startDay} ${startMonth} – ${endDay} ${endMonth} ${endYear}`;
}
