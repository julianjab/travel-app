import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/models/member.dart';
import 'package:vamos/data/repositories/firestore_member_repository.dart';
import 'package:vamos/data/repositories/firestore_user_repository.dart';
import 'package:vamos/data/repositories/member_repository.dart';
import 'package:vamos/data/repositories/user_repository.dart';

// ---------------------------------------------------------------------------
// Transient onboarding state — held in the notifier during the 3-screen flow.
// ---------------------------------------------------------------------------

/// Mutable state accumulated across the 3 onboarding screens (F1.4 → F1.4b
/// → F1.5) before the final `submitOnboarding` write.
class JoinOnboardingState {
  const JoinOnboardingState({
    this.displayName = '',
    this.alias = '',
    this.dietTags = const [],
    this.paceTags = const [],
    this.budget = '',
  });

  /// Global profile name (collected in F1.4 for new users).
  final String displayName;

  /// Trip-specific alias (collected in F1.4b for all users).
  final String alias;

  /// Multi-select diet restrictions (F1.5).
  final List<String> dietTags;

  /// Multi-select pace preferences (F1.5).
  final List<String> paceTags;

  /// Single-select budget preference — empty string if not selected (F1.5).
  final String budget;

  JoinOnboardingState copyWith({
    String? displayName,
    String? alias,
    List<String>? dietTags,
    List<String>? paceTags,
    String? budget,
  }) {
    return JoinOnboardingState(
      displayName: displayName ?? this.displayName,
      alias: alias ?? this.alias,
      dietTags: dietTags ?? this.dietTags,
      paceTags: paceTags ?? this.paceTags,
      budget: budget ?? this.budget,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the join-trip onboarding flow (F1.4 → F1.4b → F1.5).
///
/// Family param is the [inviteCode] from the deep link — it is fixed for the
/// duration of the onboarding and is used in [submitOnboarding].
///
/// State lifecycle:
///   - `AsyncData(null)` — idle (flow in progress, no write yet).
///   - `AsyncLoading()` — [submitOnboarding] in flight.
///   - `AsyncData(null)` — write completed successfully.
///   - `AsyncError(e, _)` — write failed (shows error in UI).
class JoinTripNotifier
    extends AutoDisposeFamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String inviteCode) async {
    // No initial side effect — the notifier starts idle.
  }

  // Transient state accumulated across screens.
  JoinOnboardingState _onboarding = const JoinOnboardingState();

  JoinOnboardingState get onboarding => _onboarding;

  // ---------------------------------------------------------------------------
  // Setters called by each screen as the user advances
  // ---------------------------------------------------------------------------

  void setDisplayName(String name) {
    _onboarding = _onboarding.copyWith(displayName: name);
  }

  void setAlias(String alias) {
    _onboarding = _onboarding.copyWith(alias: alias);
  }

  void setDietTags(List<String> tags) {
    _onboarding = _onboarding.copyWith(dietTags: tags);
  }

  void setPaceTags(List<String> tags) {
    _onboarding = _onboarding.copyWith(paceTags: tags);
  }

  void setBudget(String budget) {
    _onboarding = _onboarding.copyWith(budget: budget);
  }

  // ---------------------------------------------------------------------------
  // Submit (called from JoinTagsScreen on "Entrar al viaje")
  // ---------------------------------------------------------------------------

  /// Persists the profile (if new user) and registers the member atomically.
  ///
  /// [tripId] is derived from the invite document by [MemberRepository.joinTrip].
  /// [userId] is the Firebase Auth uid of the authenticated user.
  /// [isNewUser] controls whether [UserRepository.saveProfile] is called.
  ///
  /// Throws [InviteLinkInactiveException] if the invite is no longer active.
  Future<void> submitOnboarding({
    required String tripId,
    required String userId,
    required bool isNewUser,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final memberRepo = ref.read(memberRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      // 1. Save global profile for new users (one-time-in-life).
      if (isNewUser && _onboarding.displayName.isNotEmpty) {
        await userRepo.saveProfile(
          userId: userId,
          displayName: _onboarding.displayName,
        );
      }

      // 2. Build tags map from the onboarding state.
      final tags = <String, dynamic>{
        'diet': _onboarding.dietTags,
        'pace': _onboarding.paceTags,
        if (_onboarding.budget.isNotEmpty) 'budget': _onboarding.budget,
      };

      // 3. Atomically write memberIds arrayUnion + memberAliases entry +
      //    member doc. memberRepo.joinTrip handles the transaction — the
      //    denormalized alias on the trip doc (X-11) is updated there.
      final member = Member(
        userId: userId,
        alias: _onboarding.alias,
        tags: tags,
        joinedAt: DateTime.now(),
      );

      await memberRepo.joinTrip(
        tripId: tripId,
        inviteCode: arg, // arg is the inviteCode family param
        member: member,
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Family param: [inviteCode] from the deep link URL.
///
/// autoDispose: the notifier (and transient onboarding state) is released
/// when the user leaves the join flow — either after success or back-press.
final joinTripProvider = AsyncNotifierProvider.autoDispose
    .family<JoinTripNotifier, void, String>(JoinTripNotifier.new);
