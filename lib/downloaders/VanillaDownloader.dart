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
    _cachedDownloads = _cacheDir.listSync();
  }

  @override
  Future<void> download(MCVersion version, Directory outDir) async {
    if (_cachedURLs[version] == null) {
      _cachedURLs[version] = await getVanillaDownloadURL(version);
    }

    final fileName = 'vanilla-$version.jar';
    final url = _cachedURLs[version];

    _logger.log('Downloading $fileName...');

    final cachedDownload = _cachedDownloads.firstWhere(
        (cachedDownload) => p.basename(cachedDownload.path) == fileName,
        orElse: () => null);

    if (cachedDownload != null) {
      _logger.log('Already downloaded $fileName, using cache');
      await cachedDownload.copy(p.join(outDir.path, fileName));
    } else {
      final response = await http.get(url);
      final cacheFile = await File(p.join(_cacheDir.path, fileName))
          .writeAsBytes(response.bodyBytes);
      _cachedDownloads.add(cacheFile);
      await cacheFile.copy(p.join(outDir.path, fileName));
    }
    _logger.log('Done downloading $fileName');
  }

  static Future<String> getVanillaDownloadURL(MCVersion version) async {
    final webScraper = WebScraper('https://mcversions.net');
    await webScraper.loadWebPage('/download/$version');
    var elements = webScraper.getElement('div.download>a.button', ['href']);
    final url = elements.first['href'];
    return url;
  }
}
