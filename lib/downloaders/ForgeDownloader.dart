import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/downloaders/ServerDownloader.dart';
import 'package:Config_Controller/downloaders/SpongeDownloader.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:web_scraper/web_scraper.dart';

class ForgeDownloader implements ServerDownloader {
  final Map<MCVersion, String> _cachedBuilds = {};
  final Directory _cacheDir;
  final bool verbose;
  final Logger _logger;

  SpongeDownloader _spongeDownloader;
  List<File> _cachedDownloads;

  ForgeDownloader(this._cacheDir, {this.verbose = false})
      : _logger = Logger(verbose) {
    _spongeDownloader = SpongeDownloader(_cacheDir, verbose: verbose);
    _cachedDownloads =
        _cacheDir.listSync().map((file) => File(file.path)).toList();
  }

  @override
  Future<void> download(MCVersion version, Directory outDir) async {
    if (!possibleVersions.contains(version)) {
      throw Exception(
          'There is no SpongeForge version for Minecraft v$version');
    }

    if (_cachedBuilds[version] == null) {
      _cachedBuilds[version] = await getLatestBuild(version);
    }

    final build = _cachedBuilds[version];
    final cacheFileName = 'forge-$version-$build.jar';
    final fileName = 'forge-installer.jar';

    _logger.log('Downloading $cacheFileName...');

    final cachedDownload = _cachedDownloads.firstWhere(
        (cachedDownload) => p.basename(cachedDownload.path) == cacheFileName,
        orElse: () => null);

    if (cachedDownload != null) {
      _logger.log('Already downloaded $cacheFileName, using cache');
      await cachedDownload.copy(p.join(outDir.path, fileName));
    } else {
      final response = await http.get(
          'https://files.minecraftforge.net/maven/net/minecraftforge/forge/$version-$build/forge-$version-$build-installer.jar');
      final cacheFile = await File(p.join(_cacheDir.path, cacheFileName))
          .writeAsBytes(response.bodyBytes);
      _cachedDownloads.add(cacheFile);
      await cacheFile.copy(p.join(outDir.path, fileName));
    }
    _logger.log('Done downloading $cacheFileName');

    await _spongeDownloader.download(version, outDir);
  }

  static Future<String> getLatestBuild(MCVersion version) async {
    final webScraper = WebScraper('https://files.minecraftforge.net');
    await webScraper
        .loadWebPage('/maven/net/minecraftforge/forge/index_$version.html');
    var elements =
        webScraper.getElement('div.download > div.title > small', []);
    final build =
        elements.last['title'].toString().replaceAll(' ', '').split('-')[1];
    return build;
  }

  static final possibleVersions = [
    MCVersion('1.8'),
    MCVersion('1.8.9'),
    MCVersion('1.9.4'),
    MCVersion('1.10.2'),
    MCVersion('1.11'),
    MCVersion('1.11.2'),
    MCVersion('1.12'),
    MCVersion('1.12.1'),
    MCVersion('1.12.2')
  ];
}
