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
  final String path;
  final bool verbose;

  final logger;

  Directory rootDir;
  Directory serversDir;
  Directory cacheDir;
  Directory configDir;
  Directory configServersDir;
  Directory configTemplatesDir;

  ConfigContoller(this.path, {this.verbose = false})
      : logger = Logger(verbose) {
    rootDir = Directory(p.join(Directory.current.path, path));
    serversDir = Directory(p.join(rootDir.path, 'servers'));
    cacheDir = Directory(p.join(rootDir.path, 'cache'));
    configDir = Directory(p.join(rootDir.path, 'config'));
    configServersDir = Directory(p.join(rootDir.path, 'config', 'servers'));
    configTemplatesDir = Directory(p.join(rootDir.path, 'config', 'templates'));
  }

  void generateConfig() async {
    logger.log(path);

    await createDirs();

    final servers = await getServers();
    await createServersDirs(servers);

    final downloaders = {
      ServerType.Paper: PaperDownloader(cacheDir, verbose: verbose),
      ServerType.Waterfall: WaterfallDownloader(cacheDir, verbose: verbose),
      ServerType.Forge: ForgeDownloader(cacheDir, verbose: verbose),
    };

    for (final server in servers) {
      await downloaders[server.type]
          .download(server.version, server.getDir(serversDir));
    }

    // await paperDownloader.download('1.16.1', outDir);
    // await paperDownloader.download('1.16.1', outDir);
    // await paperDownloader.download('1.12.2', outDir);
    // await waterfallDownloader.download('1.16', outDir);
    // await waterfallDownloader.download('1.16', outDir);
    // await waterfallDownloader.download('1.12', outDir);
    // await forgeDownloader.download('1.16.1', outDir);
    // await forgeDownloader.download('1.16.1', outDir);
    // await forgeDownloader.download('1.12.2', outDir);
  }

  Future<List<Server>> getServers() async {
    // ignore: omit_local_variable_types
    final List<Server> servers = [];
    final subFolders = configServersDir.listSync();
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
      logger.log('Found Server "${server.name}" (ID: ${server.id})');
    }
    return servers;
  }

  void createDirs() async {
    if (!(await rootDir.exists())) {
      logger.log('Creating ${rootDir.path}...');
      await rootDir.create();
    }
    if (!(await serversDir.exists())) {
      logger.log('Creating ${serversDir.path}...');
      await serversDir.create();
    }
    if (!(await cacheDir.exists())) {
      logger.log('Creating ${cacheDir.path}...');
      await cacheDir.create();
    }
    if (!(await configDir.exists())) {
      logger.log('Creating ${configDir.path}...');
      await configDir.create();
    }
    if (!(await configServersDir.exists())) {
      logger.log('Creating ${configServersDir.path}...');
      await configServersDir.create();
    }
    if (!(await configTemplatesDir.exists())) {
      logger.log('Creating ${configTemplatesDir.path}...');
      await configTemplatesDir.create();
    }
  }

  void createServersDirs(List<Server> serversList) async {
    for (final server in serversList) {
      final serverDir = server.getDir(serversDir);
      if (!(await serverDir.exists())) {
        logger.log('Creating ${serverDir.path}...');
        await serverDir.create();
      }
    }
  }
}
