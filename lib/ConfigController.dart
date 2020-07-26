import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/config/ConfigParser.dart';
import 'package:Config_Controller/downloaders/PaperDownloader.dart';
import 'package:Config_Controller/downloaders/WaterfallDownloader.dart';
import 'package:Config_Controller/helpers.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import 'config/Server.dart';
import 'config/Template.dart';
import 'downloaders/ForgeDownloader.dart';

class ConfigContoller {
  final String _path;
  final bool verbose;

  Directory _rootDir;
  Directory _serversDir;
  Directory _cacheDir;
  Directory _configDir;
  Directory _serversConfigDir;
  Directory _templatesConfigDir;

  Logger _logger;

  ConfigContoller(this._path, {this.verbose = false}) {
    _rootDir = Directory(p.join(Directory.current.path, _path));
    _serversDir = Directory(p.join(_rootDir.path, 'servers'));
    _cacheDir = Directory(p.join(_rootDir.path, 'cache'));
    _configDir = Directory(p.join(_rootDir.path, 'config'));
    _serversConfigDir = Directory(p.join(_rootDir.path, 'config', 'servers'));
    _templatesConfigDir =
        Directory(p.join(_rootDir.path, 'config', 'templates'));

    _logger = LoggerProvider.logger;
  }

  void generateConfig(bool install) async {
    await createDirs();

    final servers = await getServers();
    final templates = await getTemplates();

    await createServersDirs(servers);

    for (final server in servers) {
      for (final template in server.getFlattenExtendsTree(templates)) {
        template
            .getConfigDir(_configDir)
            .listSync(recursive: true)
            .forEach((templateFileSystemEntity) {
          if (templateFileSystemEntity is File) {
            final regex = RegExp(r'/^(templates|servers)/(.+?)//');
            final relPath = templateFileSystemEntity.path.replaceAll(regex, '');
            // print(relPath);
            // regex.firstMatch(templateFileSystemEntity);
            mergeFiles(templateFileSystemEntity);
            //print(templateFileSystemEntity);
          }
        });
      }
      if (install) {
        final downloaders = {
          ServerType.Paper: PaperDownloader(_cacheDir, verbose: verbose),
          ServerType.Waterfall:
              WaterfallDownloader(_cacheDir, verbose: verbose),
          ServerType.Forge: ForgeDownloader(_cacheDir, verbose: verbose),
        };
        await downloaders[server.type]
            .download(server.version, server.getDir(_serversDir));
      }
    }
  }

  Future<List<Server>> getServers() async {
    // ignore: omit_local_variable_types
    final List<Server> servers = [];
    final subFolders = _serversConfigDir.listSync();
    for (Directory folder in subFolders) {
      final file = File(p.join(folder.path, 'config.json'));
      if ((await file.exists())) {
        final rawConfig = await file.readAsString();
        final config = ConfigParser.parseJSON(rawConfig);
        final possibleTypes = {
          'paper': ServerType.Paper,
          'waterfall': ServerType.Waterfall,
          'forge': ServerType.Forge
        };
        final server = Server(
          id: folder.path.split(Platform.pathSeparator).last,
          name: config['name'],
          type: possibleTypes[config['type']],
          version: MCVersion(config['version']),
          extendsTemplates: (config['extends'] as List<dynamic>)
              .map((v) => v.toString())
              .toList(),
          restricted: config['restricted'],
          port: config['port'],
        );
        servers.add(server);
        _logger.v('Found $server');
      } else {
        _logger.w('No config file found in ${folder.path}');
      }
    }
    return servers;
  }

  Future<List<Template>> getTemplates() async {
    // ignore: omit_local_variable_types
    final List<Template> templates = [];
    final subFolders = _templatesConfigDir.listSync();
    for (Directory folder in subFolders) {
      final file = File(p.join(folder.path, 'config.json'));
      if ((await file.exists())) {
        final rawConfig = await file.readAsString();
        final config = ConfigParser.parseJSON(rawConfig);
        final template = Template(
          id: folder.path.split(Platform.pathSeparator).last,
          name: config['name'],
          extendsTemplates: (config['extends'] as List<dynamic>)
              .map((v) => v.toString())
              .toList(),
        );
        templates.add(template);
        _logger.v('Found $template');
      } else {
        _logger.w('No config file found in ${folder.path}');
      }
    }
    return templates;
  }

  void createDirs() async {
    await createDir(_rootDir);
    await createDir(_serversDir);
    await createDir(_cacheDir);
    await createDir(_configDir);
    await createDir(_serversConfigDir);
    await createDir(_templatesConfigDir);
  }

  void createServersDirs(List<Server> serversList) async {
    for (final server in serversList) {
      final serverDir = server.getDir(_serversDir);
      await createDir(serverDir);
    }
  }

  void mergeFiles(File configFile) async {
    final rawConfig = await configFile.readAsString();
    // final serverConfig = ConfigParser.parseJSON(rawConfig);
    final ext = p.extension(configFile.path);
    print(ext);
    // print(serverConfig);
    switch (ext) {
      case '.yaml':
      case '.yml':
        print('yaml');
        // final oldContent = ConfigParser.parseYAML(templateRawConfig);
        // final newContent = ConfigParser.parseYAML(newRawConfig);
        // print(oldContent);
        // print(newContent);
        //     oldContent = YAML.parse(fs.readFileSync(serverP).toString());
        //     newContent = YAML.parse(newContent);
        //     toWrite = YAML.stringify({ ...oldContent, ...newContent });
        break;
      case '.json':
        print('json');
        final oldContent = ConfigParser.parseJSON(rawConfig);
        // final newContent = ConfigParser.parseJSON(rawConfig);
        print(oldContent);
        // print(newContent);
        //     oldContent = JSON.parse(fs.readFileSync(serverP));
        //     newContent = JSON.parse(newContent);
        //     toWrite = JSON.stringify({ ...oldContent, ...newContent });
        break;
      case '.properties':
        print('properties');
        // final oldContent = ConfigParser.parseProperties(templateRawConfig);
        // final newContent = ConfigParser.parseProperties(newRawConfig);
        // print(oldContent);
        // print(newContent);
        //     oldContent = PROPERTIES.parse(
        //       fs.readFileSync(serverP).toString(),
        //     );
        //     newContent = PROPERTIES.parse(newContent);
        //     toWrite = JSON.stringify({ ...oldContent, ...newContent });
        break;
      default:
        _logger.w("${ext} isn't supported, overwriting...");
        break;
    }
  }
}
