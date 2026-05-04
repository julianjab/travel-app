import 'package:flutter/material.dart';
import 'vamos_colors.dart';
import 'vamos_typography.dart';

/// Lockup completo de Vamos: vam◯s
///
/// - size ≥ 48 → con sombra elíptica abajo del punto
/// - size < 48 → sin sombra (regla del sistema)
///
/// Forzar sombra: pasar withShadow: true
/// Forzar sin:    pasar withShadow: false
class VamosLogo extends StatelessWidget {
  final double size;
  final Color? textColor;
  final Color? dotColor;
  final bool? withShadow;

  const VamosLogo({
    super.key,
    this.size = 32,
    this.textColor,
    this.dotColor,
    this.withShadow,
  });

  @override
  Widget build(BuildContext context) {
    final useShadow = withShadow ?? size >= 48;
    final dot = dotColor ?? VamosColors.sol500;
    final txt = textColor ?? Theme.of(context).colorScheme.onSurface;

    final dotSize = size * 0.78; // diámetro del punto ≈ altura-x

    return SizedBox(
      height: useShadow ? size * 1.18 : size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'vam',
            style: TextStyle(
              fontFamily: VamosTypography.fontDisplay,
              fontWeight: FontWeight.w700,
              fontSize: size,
              letterSpacing: size * -0.05,
              height: 1.0,
              color: txt,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.02),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: dotSize,
                  height: dotSize,
                  child: Container(
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                ),
                if (useShadow) ...[
                  SizedBox(height: size * 0.08),
                  Container(
                    width: dotSize * 0.78,
                    height: size * 0.05,
                    decoration: BoxDecoration(
                      color: dot.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(size),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            's',
            style: TextStyle(
              fontFamily: VamosTypography.fontDisplay,
              fontWeight: FontWeight.w700,
              fontSize: size,
              letterSpacing: size * -0.05,
              height: 1.0,
              color: txt,
            ),
          ),
        ],
      ),
    );
  }
}

/// Solo el punto · para app icon, favicon, splash, marcadores
class VamosLogoMark extends StatelessWidget {
  final double size;
  final Color? color;

  const VamosLogoMark({super.key, this.size = 64, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? VamosColors.sol500,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
