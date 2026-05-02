import 'package:flutter/material.dart';

/// Escala de espaciado de Vamos. Múltiplos de 8 (con un xs=4 para casos muy ajustados).
/// Uso: Padding(padding: EdgeInsets.all(VamosSpacing.md))
class VamosSpacing {
  VamosSpacing._();

  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Radios estándar.
class VamosRadius {
  VamosRadius._();

  static const Radius sm   = Radius.circular(6);
  static const Radius md   = Radius.circular(10);
  static const Radius lg   = Radius.circular(14);
  static const Radius xl   = Radius.circular(20);
  static const Radius full = Radius.circular(9999);

  static const BorderRadius brSm = BorderRadius.all(sm);
  static const BorderRadius brMd = BorderRadius.all(md);
  static const BorderRadius brLg = BorderRadius.all(lg);
  static const BorderRadius brXl = BorderRadius.all(xl);
}

/// Sombras estándar.
class VamosShadow {
  VamosShadow._();

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0F1A1612), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x1A1A1612), offset: Offset(0, 4), blurRadius: 12),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x241A1612), offset: Offset(0, 8), blurRadius: 24),
  ];
}
