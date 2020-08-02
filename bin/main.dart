import 'dart:io';

import 'package:Config_Controller/ConfigController.dart';
import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/UpdateManager.dart';
import 'package:args/args.dart';
import 'package:json_schema/vm.dart';

Future<void> main(List<String> arguments) async {
  final stopwatch = Stopwatch()..start();

  final parser = ArgParser();

  parser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  parser.addFlag('install', abbr: 'i', defaultsTo: false);
  parser.addFlag('debug', abbr: 'd', defaultsTo: false);
  parser.addFlag('backup', abbr: 'b', defaultsTo: false);
  parser.addOption('path', abbr: 'p', defaultsTo: '.');

  final parsed = parser.parse(arguments);

  LoggerProvider.init(parsed['verbose'], parsed['debug']);
  final logger = LoggerProvider.logger;

  if (parsed['path'] == null) {
    return logger.e('Please specify a folder (config-controller -p <path>)');
  }

  configureJsonSchemaForVm();

  await UpdateManager.printUpdateMessage();

  final cfgController = ConfigContoller(parsed['path']);
  await cfgController.generateConfig(
    parsed['install'],
    parsed['backup'],
  );

  logger.i(
      'Done in ${stopwatch.elapsed.inSeconds}s (${stopwatch.elapsedMilliseconds} ms) !');
  exit(0);
}
