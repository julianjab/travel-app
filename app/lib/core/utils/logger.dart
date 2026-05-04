import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

// App-wide logger. Use `log.d(...)`, `log.i(...)`, `log.w(...)`, `log.e(...)`.
// Debug builds: all levels. Release builds: warnings and above only.
final log = Logger(
  level: kDebugMode ? Level.debug : Level.warning,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: kDebugMode,
    printEmojis: true,
  ),
);
