import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/config/ConfigParser.dart';
import 'package:Config_Controller/config/ConfigSerializer.dart';
import 'package:path/path.dart' as p;

Future<void> createDir(Directory dir) async {
  final logger = LoggerProvider.logger;
  try {
    if (!(await dir.exists())) {
      logger.v('Creating ${dir.path}...');
      await dir.create(recursive: true);
    }
  } on FileSystemException catch (e) {
    logger.e(e.osError.message, 'Creation of ${dir.path} failed');
    exit(1);
  }
}

Future<void> createFile(File file, {String defaultContent = ''}) async {
  final logger = LoggerProvider.logger;
  try {
    if (!(await file.exists())) {
      logger.v('Creating ${file.path}...');
      await file.create(recursive: true);
      await file.writeAsString(defaultContent);
    }
  } on FileSystemException catch (e) {
    logger.e(e.osError.message, 'Creation of ${file.path} failed');
    exit(1);
  }
}

void mergeConfigFiles(File srcFile, File targetFile, Map variables) async {
  final logger = LoggerProvider.logger;

  final ext1 = p.extension(srcFile.path);
  final ext2 = p.extension(targetFile.path);
  if (ext1 != ext2) {
    logger.e(
        '${srcFile.path} and ${targetFile.path} don\'t have the same extension');
    exit(1);
  }

  await Future.wait([createFile(srcFile), createFile(targetFile)]);

  final srcFileContent =
      ConfigParser.parseVars(await srcFile.readAsString(), variables);
  final targetFileContent =
      ConfigParser.parseVars(await targetFile.readAsString(), variables);
  String toWrite;

  if (targetFileContent != '') {
    try {
      switch (ext1) {
        case '.yaml':
        case '.yml':
          final parsedSrc = ConfigParser.parseYAML(srcFileContent);
          final parsedTarget = ConfigParser.parseYAML(targetFileContent);
          toWrite =
              ConfigSerializer.serializeYAML({...parsedSrc, ...parsedTarget});
          break;
        case '.json':
          final parsedSrc = ConfigParser.parseJSON(srcFileContent);
          final parsedTarget = ConfigParser.parseJSON(targetFileContent);
          toWrite =
              ConfigSerializer.serializeJSON({...parsedSrc, ...parsedTarget});
          break;
        case '.properties':
          final parsedSrc = ConfigParser.parseProperties(srcFileContent);
          final parsedTarget = ConfigParser.parseProperties(targetFileContent);
          toWrite = ConfigSerializer.serializeProperties(
              {...parsedSrc, ...parsedTarget});
          break;
        default:
          logger.v(
              "${ext1} merging isn't supported, overwriting ${targetFile.path}...");
          toWrite = srcFileContent;
          break;
      }
    } catch (e) {
      logger.e(
          'Bad formatting in either file ${srcFile.path} or file ${targetFile.path}');
      exit(1);
    }
  } else {
    toWrite = srcFileContent;
  }

  await targetFile.writeAsString(toWrite);
}
