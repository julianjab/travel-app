import 'package:flutter/material.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';

/// Renders either the trip's cover photo or a colored placeholder with the
/// trip name's first letter.
///
/// Color is derived deterministically from [tripName] via a simple hash so
/// each trip always gets the same hue across app restarts.
/// Defined in wireframe F1.1 and data model §3.9.
class CoverPlaceholder extends StatelessWidget {
  const CoverPlaceholder({
    super.key,
    required this.tripName,
    this.coverPhotoURL,
    this.height = 140,
    this.borderRadius,
  });

  final String tripName;
  final String? coverPhotoURL;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ??
        const BorderRadius.only(
          topLeft: VamosRadius.lg,
          topRight: VamosRadius.lg,
        );

    if (coverPhotoURL != null && coverPhotoURL!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          coverPhotoURL!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _Placeholder(
            tripName: tripName,
            height: height,
            borderRadius: radius,
          ),
        ),
      );
    }

    return _Placeholder(
      tripName: tripName,
      height: height,
      borderRadius: radius,
    );
  }
}

// ---------------------------------------------------------------------------
// Internal placeholder — not exported
// ---------------------------------------------------------------------------

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.tripName,
    required this.height,
    required this.borderRadius,
  });

  final String tripName;
  final double height;
  final BorderRadius borderRadius;

  /// Derives a deterministic color from the trip name using a simple hash.
  /// The hash is mapped to one of several distinct hues so nearby trips
  /// don't end up with the same color by accident.
  Color _colorFromName(String name) {
    // djb2-style hash on the name string.
    var hash = 5381;
    for (final codeUnit in name.codeUnits) {
      hash = ((hash << 5) + hash) + codeUnit;
      hash &= 0xFFFFFFFF; // keep 32-bit
    }
    // Map hash to one of 8 distinct hues (evenly spaced on the color wheel).
    const hues = [200.0, 340.0, 120.0, 270.0, 30.0, 180.0, 300.0, 60.0];
    final hue = hues[hash.abs() % hues.length];
    return HSLColor.fromAHSL(1.0, hue, 0.45, 0.48).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final initial =
        tripName.isNotEmpty ? tripName.trim()[0].toUpperCase() : '?';
    final bgColor = _colorFromName(tripName);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        height: height,
        width: double.infinity,
        color: bgColor,
        alignment: Alignment.center,
        child: Text(
          initial,
          style: text.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Token extension: cover image height
// ---------------------------------------------------------------------------

/// Height of the trip cover image / placeholder in the F1.1 list cards.
/// Defined here so it's easy to adjust without hunting for raw numbers.
const double kTripCoverHeight = VamosSpacing.xxl * 3; // 144 logical pixels
