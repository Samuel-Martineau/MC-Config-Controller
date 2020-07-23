import 'package:colorize/colorize.dart';

class Logger {
  final bool verbose;

  Logger(this.verbose);

  void log(String msg) {
    if (verbose) {
      final prefix = Colorize('[VERBOSE]');
      prefix.green();
      prefix.bold();

      final message = Colorize(msg);
      message.white();

      print('$prefix $message');
    }
  }
}
