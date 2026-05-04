import 'package:flutter/material.dart';
import 'package:vamos/core/theme/vamos_colors.dart';

/// Standard loading indicator for list screens.
///
/// Centered [CircularProgressIndicator] in VamosColors.sol500.
/// Used in 4+ screens — qualifies for `shared/widgets/`.
class VamosLoadingIndicator extends StatelessWidget {
  const VamosLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: VamosColors.sol500,
      ),
    );
  }
}
