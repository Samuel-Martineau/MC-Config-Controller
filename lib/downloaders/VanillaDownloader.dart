import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/downloaders/ServerDownloader.dart';
import 'package:Config_Controller/helpers.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:web_scraper/web_scraper.dart';

class VanillaDownloader implements ServerDownloader {
  final Map<MCVersion, String> _cachedURLs = {};
  final Directory _cacheDir;
  final bool verbose;

  Logger _logger;

  List<File> _cachedDownloads;

  VanillaDownloader(this._cacheDir, {this.verbose = false}) {
    _cachedDownloads =
        _cacheDir.listSync().map((file) => File(file.path)).toList();
    _logger = LoggerProvider.logger;
  }

  @override
  Future<void> download(MCVersion version, Directory outDir) async {
    _logger = LoggerProvider.logger;
    if (_cachedURLs[version] == null) {
      _cachedURLs[version] = await getVanillaDownloadURL(version);
    }

    final cacheFileName = 'vanilla-$version.jar';
    final fileName = 'mojang_$version.jar';
    final url = _cachedURLs[version];

    _logger.i('Downloading $cacheFileName...');

    final cachedDownload = _cachedDownloads.firstWhere(
        (cachedDownload) => p.basename(cachedDownload.path) == cacheFileName,
        orElse: () => null);

    final localCacheDir = Directory(p.join(outDir.path, 'cache'));
    await createDir(localCacheDir);

    if (cachedDownload != null) {
      _logger.i('Already downloaded $cacheFileName, using cache');
      await cachedDownload.copy(p.join(localCacheDir.path, fileName));
    } else {
      try {
        final response = await http.get(url);
        final cacheFile = await File(p.join(_cacheDir.path, cacheFileName))
            .writeAsBytes(response.bodyBytes);
        _cachedDownloads.add(cacheFile);
        await cacheFile.copy(p.join(localCacheDir.path, fileName));
      } on SocketException catch (e) {
        _logger.e(e.message, 'Could not reach the Mojang website');
        _logger.d(e);
        exit(1);
      }
    }
    _logger.i('Done downloading $cacheFileName');
  }

  static Future<String> getVanillaDownloadURL(MCVersion version) async {
    final logger = LoggerProvider.logger;
    logger.v('Fetching the Minecraft download URL...');
    try {
      final webScraper = WebScraper('https://mcversions.net');
      await webScraper.loadWebPage('/download/$version');
      final elements = webScraper.getElement('div.download>a.button', ['href']);
      final url = elements.first['attributes']['href'];
      return url;
    } on WebScraperException catch (e) {
      logger.e(e.errorMessage(), 'Could not reach the MCVersions website');
      logger.d(e);
      exit(1);
    }
  }
}
