import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/downloaders/ServerDownloader.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:web_scraper/web_scraper.dart';

class VanillaDownloader implements ServerDownloader {
  final Map<MCVersion, String> _cachedURLs = {};
  final Directory _cacheDir;
  final Logger _logger;
  final bool verbose;

  List<File> _cachedDownloads;

  VanillaDownloader(this._cacheDir, {this.verbose = false})
      : _logger = Logger(verbose) {
    _cachedDownloads =
        _cacheDir.listSync().map((file) => File(file.path)).toList();
  }

  @override
  Future<void> download(MCVersion version, Directory outDir) async {
    if (_cachedURLs[version] == null) {
      _cachedURLs[version] = await getVanillaDownloadURL(version);
    }

    final cacheFileName = 'vanilla-$version.jar';
    final fileName = 'mojang_$version.jar';
    final url = _cachedURLs[version];

    _logger.log('Downloading $cacheFileName...');

    final cachedDownload = _cachedDownloads.firstWhere(
        (cachedDownload) => p.basename(cachedDownload.path) == cacheFileName,
        orElse: () => null);

    final subCacheDir = Directory(p.join(outDir.path, 'cache'));
    if (!(await subCacheDir.exists())) {
      _logger.log('Creating ${subCacheDir.path}...');
      await subCacheDir.create();
    }

    if (cachedDownload != null) {
      _logger.log('Already downloaded $cacheFileName, using cache');
      await cachedDownload.copy(p.join(subCacheDir.path, fileName));
    } else {
      final response = await http.get(url);
      final cacheFile = await File(p.join(_cacheDir.path, cacheFileName))
          .writeAsBytes(response.bodyBytes);
      _cachedDownloads.add(cacheFile);
      await cacheFile.copy(p.join(subCacheDir.path, fileName));
    }
    _logger.log('Done downloading $cacheFileName');
  }

  static Future<String> getVanillaDownloadURL(MCVersion version) async {
    final webScraper = WebScraper('https://mcversions.net');
    await webScraper.loadWebPage('/download/$version');
    final elements = webScraper.getElement('div.download>a.button', ['href']);
    final url = elements.first['attributes']['href'];
    return url;
  }
}
