import 'package:Config_Controller/ConfigController.dart';
import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/UpdateManager.dart';
import 'package:args/args.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser();

  parser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  parser.addFlag('install', abbr: 'i', defaultsTo: false);
  parser.addFlag('debug', abbr: 'd', defaultsTo: false);
  parser.addOption('path', abbr: 'p');

  final parsed = parser.parse(arguments);

  LoggerProvider.init(parsed['verbose'], parsed['debug']);

  if (parsed['path'] == null) {
    return LoggerProvider.logger
        .e('Please specify a folder (config-controller -p <path>)');
  }

  await UpdateManager.printUpdateMessage();

  final cfgController = ConfigContoller(parsed['path']);
  cfgController.generateConfig(parsed['install']);
}
