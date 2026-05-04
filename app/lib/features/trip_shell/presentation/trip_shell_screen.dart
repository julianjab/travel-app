import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/data/repositories/firestore_trip_repository.dart';
import 'package:vamos/features/expenses/presentation/expenses_screen.dart';
import 'package:vamos/features/itinerary/presentation/itinerary_screen.dart';
import 'package:vamos/features/members/presentation/members_screen.dart';
import 'package:vamos/shared/widgets/loading_indicator.dart';

// ---------------------------------------------------------------------------
// Trip stream provider (family) — scoped to this file
// ---------------------------------------------------------------------------

/// Streams the full [Trip] object for use in the shell and its child tabs.
final _tripProvider =
    StreamProvider.autoDispose.family<Trip?, String>((ref, tripId) {
  return ref.watch(tripRepositoryProvider).watchById(tripId);
});

// ---------------------------------------------------------------------------
// Trip shell screen
// ---------------------------------------------------------------------------

/// Tabbed container for the in-trip views: Itinerario, Gastos, Gente.
///
/// Renders a bottom [TabBar] with three tabs. The AppBar title streams the trip
/// name from Firestore, showing "Cargando..." while the snapshot is not yet
/// available.
class TripShellScreen extends ConsumerStatefulWidget {
  const TripShellScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripShellScreen> createState() => _TripShellScreenState();
}

class _TripShellScreenState extends ConsumerState<TripShellScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(_tripProvider(widget.tripId));
    final trip = tripAsync.value;
    final tripName = trip?.name ?? 'Cargando...';

    return Scaffold(
      backgroundColor: VamosColors.bg,
      appBar: AppBar(
        backgroundColor: VamosColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          tripName,
          style: VamosTypography.headlineMedium,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: VamosTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: VamosTypography.caption,
          labelColor: VamosColors.sol500,
          unselectedLabelColor: VamosColors.text3,
          indicatorColor: VamosColors.sol500,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Itinerario'),
            Tab(text: 'Gastos'),
            Tab(text: 'Gente'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // F2 — Itinerario (live when trip is loaded, loading spinner otherwise)
          trip != null
              ? ItineraryScreen(tripId: widget.tripId, trip: trip)
              : const VamosLoadingIndicator(),
          // F3 — Gastos (live when trip is loaded, loading spinner otherwise)
          trip != null
              ? ExpensesScreen(tripId: widget.tripId, trip: trip)
              : const VamosLoadingIndicator(),
          // F4.1 — Miembros (live)
          MembersScreen(tripId: widget.tripId),
        ],
      ),
    );
  }
}

