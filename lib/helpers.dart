import 'dart:io';

import 'package:Config_Controller/Logger.dart';

void createDir(Directory dir) async {
  final logger = LoggerProvider.logger;
  try {
    if (!(await dir.exists())) {
      logger.v('Creating ${dir.path}...');
      await dir.create();
    }
  } catch (e) {
    final error = e as FileSystemException;
    logger.e(error.osError.message, 'Creation of ${dir.path} failed');
    exit(1);
  }
}
