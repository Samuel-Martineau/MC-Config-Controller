import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/config/ConfigParser.dart';
import 'package:Config_Controller/downloaders/ForgeDownloader.dart';
import 'package:Config_Controller/downloaders/PaperDownloader.dart';
import 'package:Config_Controller/downloaders/WaterfallDownloader.dart';
import 'package:Config_Controller/helpers.dart';
import 'package:archive/archive_io.dart';
import 'package:globbing/globbing.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import 'config/Server.dart';
import 'config/Template.dart';

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

  void generateConfig(bool install, bool shouldMakeBackup) async {
    await createDirs();

    final servers = await getServers();
    final templates = await getTemplates();

    await createServersDirs(servers);

    if (shouldMakeBackup) makeBackup();

    await clearOldConfigFiles(servers, templates);

    final globalVars = await globalVariables;
    final serverMaps = servers.map((s) => s.toMap()).toList();

    for (final server in servers) {
      for (final template in server.getFlattenExtendsTree(templates)) {
        for (final fileSystemEntity
            in template.getConfigDir(_configDir).listSync(recursive: true)) {
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

              await mergeConfigFiles(File(srcPath), File(distPath), vars);
            }
          }
        }
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
      try {
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
            keepFiles: (config['keepFiles'] as List<dynamic>)
                .map((v) => v.toString())
                .toList(),
            variables: config['variables'],
          );
          servers.add(server);
          _logger.v('Found $server');
        } else {
          _logger.w('No config file found in ${folder.path}');
        }
      } catch (e) {
        _logger.e(
            '${folder.path}${Platform.pathSeparator}config.json isn\'t valid');
        _logger.d(e);
        exit(1);
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
      try {
        if ((await file.exists())) {
          final rawConfig = await file.readAsString();
          final config = ConfigParser.parseJSON(rawConfig);
          final template = Template(
            id: folder.path.split(Platform.pathSeparator).last,
            name: config['name'],
            extendsTemplates: (config['extends'] as List<dynamic>)
                .map((v) => v.toString())
                .toList(),
            keepFiles: (config['keepFiles'] as List<dynamic>)
                .map((v) => v.toString())
                .toList(),
          );
          templates.add(template);
          _logger.v('Found $template');
        } else {
          _logger.w('No config file found in ${folder.path}');
        }
      } catch (e) {
        _logger.e(
            '${folder.path}${Platform.pathSeparator}config.json isn\'t valid');
        _logger.d(e);
        exit(1);
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

  void clearOldConfigFiles(
    List<Server> servers,
    List<Template> templates,
  ) async {
    final rawKeepFiles = [
      'server.jar',
      'forge-installer.jar',
      'cache/mojang_**.jar',
      'mods/sponge-**-**.jar'
    ];
    final serverIDs = servers.map((s) => s.id).toList();
    for (final server in servers) {
      final localRawKeepFiles = [...rawKeepFiles];
      final localRawRemoveFiles = [...rawKeepFiles];
      for (final template in server.getFlattenExtendsTree(templates)) {
        localRawKeepFiles.addAll(template.keepFiles);
        localRawRemoveFiles.addAll(template.removeFiles);
      }
      final localKeepFiles = localRawKeepFiles.map((elem) => Glob(elem));
      final localRemoveFiles = localRawRemoveFiles.map((elem) => Glob(elem));
      final serverFiles = server.getDir(_serversDir).listSync(recursive: true);
      for (final fileSystemEntity in serverFiles) {
        final relPath = p.relative(
          fileSystemEntity.path,
          from: server.getDir(_serversDir).path,
        );
        if (fileSystemEntity is File) {
          if (localKeepFiles.any((glob) => glob.match(relPath))) {
            if (localRemoveFiles.any((glob) => glob.match(relPath))) {
              await fileSystemEntity.delete();
            }
          } else {
            await fileSystemEntity.delete();
          }
        }
      }
    }
    for (final fileSystemEntity in _serversDir.listSync()) {
      final relPath = p.relative(fileSystemEntity.path, from: _serversDir.path);
      if (!serverIDs.contains(relPath)) {
        await fileSystemEntity.delete(recursive: true);
      }
    }
  }

  void makeBackup() {
    final zipEncoder = ZipFileEncoder();
    final archiveName = 'servers-${DateTime.now().toIso8601String()}.zip';
    final archvivePath = p.join(_rootDir.path, archiveName);
    zipEncoder.create(archvivePath);
    for (final file in _serversDir.listSync(recursive: true)) {
      if (file is File) {
        _logger.v('Adding ${file.path} to the archive...');
        zipEncoder.addFile(file);
      }
    }
    zipEncoder.close();
    _logger.i('Done backuping ${_serversDir.path} into $archvivePath');
  }
}
