class Logger {
  final bool verbose;

  Logger(this.verbose);

  void log(String msg) {
    if (verbose) {
      print(msg);
    }
  }
}
