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
    _serversConfigDir = Directory(p.join(_configDir.path, 'servers'));
    _templatesConfigDir = Directory(p.join(_configDir.path, 'templates'));

    _logger = LoggerProvider.logger;
  }

  void generateConfig(bool install) async {
    await createDirs();

    final servers = await getServers();
    final templates = await getTemplates();

    await createServersDirs(servers);

    await clearOldConfigFiles();

    final globalVars = await globalVariables;
    final serverMaps = servers.map((s) => s.toMap()).toList();

    for (final server in servers) {
      for (final template in server.getFlattenExtendsTree(templates)) {
        template
            .getConfigDir(_configDir)
            .listSync(recursive: true)
            .forEach((fileSystemEntity) {
          if (fileSystemEntity is File) {
            final relPath = fileSystemEntity.path.replaceFirst(
                '${template.getConfigDir(_configDir).path}${Platform.pathSeparator}',
                '');
            if (relPath != 'config.json') {
              final srcPath = fileSystemEntity.path;
              final distPath = p.join(server.getDir(_serversDir).path, relPath);

              final vars = {
                'global': globalVars,
                'servers': serverMaps,
                'server': server.toMap()
              };

              mergeConfigFiles(File(srcPath), File(distPath), vars);
            }
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
          variables: config['variables'],
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
    await Future.wait([
      createDir(_rootDir),
      createDir(_serversDir),
      createDir(_cacheDir),
      createDir(_configDir),
      createDir(_serversConfigDir),
      createDir(_templatesConfigDir)
    ]);
  }

  void createServersDirs(List<Server> serversList) async {
    for (final server in serversList) {
      final serverDir = server.getDir(_serversDir);
      await createDir(serverDir);
    }
  }

  Future<Map> get globalVariables async {
    final globalVarsFile = File(p.join(_configDir.path, 'variables.json'));
    await createFile(globalVarsFile, defaultContent: '{}');
    return ConfigParser.parseJSON(await globalVarsFile.readAsString());
  }

  void clearOldConfigFiles() async {
    final configFiles = _serversDir.listSync(recursive: true);
    for (FileSystemEntity configFile in configFiles) {
      if (configFile is File) {
        final ext = p.extension(configFile.path);
        if (ext != '.jar') {
          await configFile.delete();
        }
      }
    }
  }
}
