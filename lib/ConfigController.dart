import 'dart:io';

import 'package:Config_Controller/ConfigParser.dart';
import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/downloaders/PaperDownloader.dart';
import 'package:Config_Controller/downloaders/WaterfallDownloader.dart';
import 'package:path/path.dart' as p;

import 'Server.dart';
import 'downloaders/ForgeDownloader.dart';

class ConfigContoller {
  final String _path;
  final bool verbose;
  final _logger;

  Directory _rootDir;
  Directory _serversDir;
  Directory _cacheDir;
  Directory _configDir;
  Directory _configServersDir;
  Directory _configTemplatesDir;

  ConfigContoller(this._path, {this.verbose = false})
      : _logger = Logger(verbose) {
    _rootDir = Directory(p.join(Directory.current.path, _path));
    _serversDir = Directory(p.join(_rootDir.path, 'servers'));
    _cacheDir = Directory(p.join(_rootDir.path, 'cache'));
    _configDir = Directory(p.join(_rootDir.path, 'config'));
    _configServersDir = Directory(p.join(_rootDir.path, 'config', 'servers'));
    _configTemplatesDir =
        Directory(p.join(_rootDir.path, 'config', 'templates'));
  }

  void generateConfig() async {
    _logger.log(_path);

    await createDirs();

    final servers = await getServers();
    await createServersDirs(servers);

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
        javaVersion: config['java'],
      );
      servers.add(server);
      _logger.log('Found Server "${server.name}" (ID: ${server.id})');
    }
    return servers;
  }

  void createDirs() async {
    if (!(await _rootDir.exists())) {
      _logger.log('Creating ${_rootDir.path}...');
      await _rootDir.create();
    }
    if (!(await _serversDir.exists())) {
      _logger.log('Creating ${_serversDir.path}...');
      await _serversDir.create();
    }
    if (!(await _cacheDir.exists())) {
      _logger.log('Creating ${_cacheDir.path}...');
      await _cacheDir.create();
    }
    if (!(await _configDir.exists())) {
      _logger.log('Creating ${_configDir.path}...');
      await _configDir.create();
    }
    if (!(await _configServersDir.exists())) {
      _logger.log('Creating ${_configServersDir.path}...');
      await _configServersDir.create();
    }
    if (!(await _configTemplatesDir.exists())) {
      _logger.log('Creating ${_configTemplatesDir.path}...');
      await _configTemplatesDir.create();
    }
  }

  void createServersDirs(List<Server> serversList) async {
    for (final server in serversList) {
      final serverDir = server.getDir(_serversDir);
      if (!(await serverDir.exists())) {
        _logger.log('Creating ${serverDir.path}...');
        await serverDir.create();
      }
    }
  }
}
