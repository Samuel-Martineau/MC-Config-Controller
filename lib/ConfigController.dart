import 'dart:io';

import 'package:Config_Controller/ConfigParser.dart';
import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/downloaders/PaperDownloader.dart';
import 'package:Config_Controller/downloaders/WaterfallDownloader.dart';
import 'package:Config_Controller/helpers.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import 'Server.dart';
import 'downloaders/ForgeDownloader.dart';

class ConfigContoller {
  final String _path;
  final bool verbose;

  Directory _rootDir;
  Directory _serversDir;
  Directory _cacheDir;
  Directory _configDir;
  Directory _configServersDir;
  Directory _configTemplatesDir;

  Logger _logger;

  ConfigContoller(this._path, {this.verbose = false}) {
    _rootDir = Directory(p.join(Directory.current.path, _path));
    _serversDir = Directory(p.join(_rootDir.path, 'servers'));
    _cacheDir = Directory(p.join(_rootDir.path, 'cache'));
    _configDir = Directory(p.join(_rootDir.path, 'config'));
    _configServersDir = Directory(p.join(_rootDir.path, 'config', 'servers'));
    _configTemplatesDir =
        Directory(p.join(_rootDir.path, 'config', 'templates'));

    _logger = LoggerProvider.logger;
  }

  void generateConfig(bool install) async {
    await createDirs();
    final servers = await getServers();
    await createServersDirs(servers);

    if (install) {
      final downloaders = {
        ServerType.Paper: PaperDownloader(_cacheDir, verbose: verbose),
        ServerType.Waterfall: WaterfallDownloader(_cacheDir, verbose: verbose),
        ServerType.Forge: ForgeDownloader(_cacheDir, verbose: verbose),
      };

      for (final server in servers) {
        await downloaders[server.type]
            .download(server.version, server.getDir(_serversDir));
      }
    }
  }

  Future<List<Server>> getServers() async {
    // ignore: omit_local_variable_types
    final List<Server> servers = [];
    final subFolders = _configServersDir.listSync();
    for (Directory folder in subFolders) {
      final file = File(p.join(folder.path, 'config.json'));
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
      _logger.v('Found Server "${server.name}" (ID: ${server.id})');
    }
    return servers;
  }

  void createDirs() async {
    await createDir(_rootDir);
    await createDir(_serversDir);
    await createDir(_cacheDir);
    await createDir(_configDir);
    await createDir(_configServersDir);
    await createDir(_configTemplatesDir);
  }

  void createServersDirs(List<Server> serversList) async {
    for (final server in serversList) {
      final serverDir = server.getDir(_serversDir);
      await createDir(serverDir);
    }
  }
}
