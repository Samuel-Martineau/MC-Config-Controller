import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/downloaders/ServerDownloader.dart';
import 'package:Config_Controller/helpers.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:web_scraper/web_scraper.dart';

class SpongeDownloader implements ServerDownloader {
  final Map<MCVersion, String> _cachedBuilds = {};
  final Directory _cacheDir;
  final bool verbose;

  Logger _logger;

  List<File> _cachedDownloads;

  SpongeDownloader(this._cacheDir, {this.verbose = false}) {
    _cachedDownloads =
        _cacheDir.listSync().map((file) => File(file.path)).toList();
  }

  @override
  Future<void> download(MCVersion version, Directory outDir) async {
    _logger = LoggerProvider.logger;
    if (_cachedBuilds[version] == null) {
      _cachedBuilds[version] = await getLatestBuild(version);
    }

    final build = _cachedBuilds[version];
    final fileName = 'sponge-$version-$build.jar';

    _logger.i('Downloading $fileName...');

    final cachedDownload = _cachedDownloads.firstWhere(
        (cachedDownload) => p.basename(cachedDownload.path) == fileName,
        orElse: () => null);

    final modsDir = Directory(p.join(outDir.path, 'mods'));
    await createDir(modsDir);

    if (cachedDownload != null) {
      _logger.i('Already downloaded $fileName, using cache');
      await cachedDownload.copy(p.join(modsDir.path, fileName));
    } else {
      try {
        final response = await http.get(
            'https://files.minecraftforge.net/maven/org/spongepowered/spongeforge/$version-2825-$build/spongeforge-$version-2825-$build.jar');
        final cacheFile = await File(p.join(_cacheDir.path, fileName))
            .writeAsBytes(response.bodyBytes);
        _cachedDownloads.add(cacheFile);
        await cacheFile.copy(p.join(modsDir.path, fileName));
      } catch (e) {
        final error = e as WebScraperException;
        _logger.e(error.errorMessage(), 'Could not reach the Sponge website');
        exit(1);
      }
    }
    _logger.i('Done downloading $fileName');
  }

  static Future<String> getLatestBuild(MCVersion version) async {
    final logger = LoggerProvider.logger;
    logger.v('Fetching the latest Sponge build...');
    try {
      final webScraper = WebScraper('https://files.minecraftforge.net');
      await webScraper.loadWebPage(
          '/maven/org/spongepowered/spongeforge/index_$version.html');
      final links = webScraper
          .getElement('div.download > div.links > div.link > a', ['href']);
      final regex = RegExp(
          r'^\/maven\/org\/spongepowered\/spongeforge\/[\d.]+-(.*)\/spongeforge-.*.\.jar$');
      Match match = regex.firstMatch(links.first['attributes']['href']);
      final build = match.group(1);
      return build;
    } catch (e) {
      final error = e as WebScraperException;
      logger.e(error.errorMessage(), 'Could not reach the Sponge website');
      exit(1);
    }
  }
}
