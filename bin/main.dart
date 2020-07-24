import 'package:Config_Controller/ConfigController.dart';
import 'package:Config_Controller/Logger.dart';
import 'package:args/args.dart';

void main(List<String> arguments) {
  final parser = ArgParser();

  parser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  parser.addFlag('skipInstall', defaultsTo: false);
  parser.addOption('path', abbr: 'p');

  final parsed = parser.parse(arguments);

  LoggerProvider.init(parsed['verbose']);

  if (parsed['path'] == null) {
    return LoggerProvider.logger
        .e('Please specify a folder (config-controller -p <path>)');
  }

  final cfgController = ConfigContoller(parsed['path']);
  cfgController.generateConfig(!parsed['skipInstall']);
}