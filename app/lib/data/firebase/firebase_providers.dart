import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the singleton [FirebaseAuth] instance.
///
/// Not autoDispose — this is a global, app-lifetime dependency.
/// Consumed by auth notifiers and the router's redirect logic.
final authProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides the singleton [FirebaseFirestore] instance.
///
/// Not autoDispose — this is a global, app-lifetime dependency.
/// Consumed only by repositories in `data/repositories/`. Never injected
/// directly into notifiers or widgets.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// authStateProvider is defined in features/auth/application/auth_notifier.dart.
// It is a global (no autoDispose) StreamProvider<User?> that the router
// refresh listens to. Import it from there — do not duplicate it here.
