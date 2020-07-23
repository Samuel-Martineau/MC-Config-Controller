import 'dart:io' as io;

import 'package:logger/logger.dart';

class LoggerProvider {
  static Logger _logger;

  static void init(bool verbose) {
    _logger = Logger(
      filter: _CustomFilter(verbose),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 6,
        colors: io.stdout.supportsAnsiEscapes,
        lineLength: io.stdout.terminalColumns,
      ),
    );
  }

  static Logger get logger {
    return _logger;
  }
}

class _CustomFilter extends LogFilter {
  final bool _verbose;

  _CustomFilter(this._verbose);

  @override
  bool shouldLog(LogEvent event) {
    switch (event.level) {
      case Level.verbose:
        return _verbose;
      default:
        return true;
    }
  }
}
