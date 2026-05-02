import 'package:flutter/material.dart';
import 'package:vamos/core/router/app_router.dart';
import 'package:vamos/core/theme/app_theme.dart';

/// App root.
///
/// Wires [GoRouter] and [AppTheme]. [ProviderScope] is set up in [main.dart].
class VamosApp extends StatelessWidget {
  const VamosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vamos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // TODO: dark theme activates when visual identity is finalized.
      // darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
