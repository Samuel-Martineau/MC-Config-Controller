import 'package:Config_Controller/ConfigController.dart';
import 'package:args/args.dart';

void main(List<String> arguments) {
  var parser = ArgParser();
  parser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  parser.addOption('path', abbr: 'p', allowMultiple: false);

  var parsed = parser.parse(arguments);

  if (parsed['path'] == null) {
    return print('Please specify a folder (config-controller -p <path>)');
  }

  final cfgController =
      ConfigContoller(parsed['path'], verbose: parsed['verbose']);
  cfgController.generateConfig();
}
