import 'package:flutter/material.dart';
import 'package:vamos/core/router/app_router.dart';
import 'package:vamos/core/theme/vamos_theme.dart';

/// App root.
///
/// Wires [GoRouter] and [VamosTheme]. [ProviderScope] is set up in [main.dart].
class VamosApp extends StatelessWidget {
  const VamosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vamos',
      debugShowCheckedModeBanner: false,
      theme: VamosTheme.light,
      darkTheme: VamosTheme.dark,
      routerConfig: router,
    );
  }
}
