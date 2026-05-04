import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/repositories/firestore_invite_repository.dart';
import 'package:vamos/data/repositories/firestore_user_repository.dart';
import 'package:vamos/data/repositories/invite_repository.dart';
import 'package:vamos/data/repositories/user_repository.dart';

// ---------------------------------------------------------------------------
// Async provider: resolves invite + user profile status in one shot
// ---------------------------------------------------------------------------

/// Holds the data resolved when entering the join flow.
class _JoinEntryData {
  const _JoinEntryData({
    required this.tripId,
    required this.isNewUser,
    required this.displayName,
  });

  final String tripId;

  /// True when `users/{uid}` does not exist yet → show F1.4 profile screen.
  final bool isNewUser;

  /// Default alias = Firebase Auth displayName or empty string.
  final String displayName;
}

/// Resolves the invite code into a trip ID and checks whether the current
/// user already has a Vamos profile.
///
/// Throws [InviteNotFoundException] if the invite document is missing or
/// inactive.
final _joinEntryProvider = FutureProvider.autoDispose
    .family<_JoinEntryData, String>((ref, inviteCode) async {
  final inviteRepo = ref.read(inviteRepositoryProvider);
  final userRepo = ref.read(userRepositoryProvider);

  // Resolve the invite doc to get tripId.
  final tripId = await inviteRepo.getTripId(inviteCode);
  if (tripId == null) throw const _InviteNotFoundException();

  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final displayName = FirebaseAuth.instance.currentUser?.displayName ?? '';

  final isNewUser = uid.isEmpty ? true : !(await userRepo.profileExists(uid));

  return _JoinEntryData(
    tripId: tripId,
    isNewUser: isNewUser,
    displayName: displayName,
  );
});

class _InviteNotFoundException implements Exception {
  const _InviteNotFoundException();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Entry point for the join flow — `/join/:code`.
///
/// Resolves the invite and profile status, then automatically navigates:
///   - New user  → /join/:code/profile (F1.4)
///   - Returning → /join/:code/alias   (F1.4b)
///
/// Shows a loading state while resolving. If the invite is invalid/inactive,
/// shows an error with a fallback to go home.
class JoinEntryScreen extends ConsumerWidget {
  const JoinEntryScreen({super.key, required this.inviteCode});

  final String inviteCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(_joinEntryProvider(inviteCode));

    return Scaffold(
      backgroundColor: VamosColors.bg,
      body: SafeArea(
        child: entryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorBody(
            message: err is _InviteNotFoundException
                ? 'Este link ya no está activo.'
                : 'No se pudo cargar el viaje. Intentá de nuevo.',
            onGoHome: () => context.go('/trips'),
          ),
          data: (entry) {
            // Navigate imperatively after the first data frame.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              if (entry.isNewUser) {
                context.pushReplacement(
                  '/join/$inviteCode/profile',
                  extra: <String, dynamic>{
                    'tripId': entry.tripId,
                    'defaultName': entry.displayName,
                  },
                );
              } else {
                context.pushReplacement(
                  '/join/$inviteCode/alias',
                  extra: <String, dynamic>{
                    'tripId': entry.tripId,
                    'isNewUser': false,
                    'defaultName': entry.displayName,
                  },
                );
              }
            });
            // Show loading while the navigation frame fires.
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error body
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onGoHome});

  final String message;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VamosSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: VamosTypography.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VamosSpacing.xl),
          FilledButton(
            onPressed: onGoHome,
            style: FilledButton.styleFrom(
              backgroundColor: VamosColors.sol500,
              shape: RoundedRectangleBorder(
                borderRadius: VamosRadius.brFull,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: VamosSpacing.xl,
                vertical: VamosSpacing.md,
              ),
            ),
            child: Text(
              'Ir al inicio',
              style: VamosTypography.titleMedium.copyWith(
                color: VamosColors.textOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
