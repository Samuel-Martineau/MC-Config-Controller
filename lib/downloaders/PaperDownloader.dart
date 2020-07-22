import 'dart:convert';
import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/downloaders/ServerDownloader.dart';
import 'package:Config_Controller/downloaders/VanillaDownloader.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class PaperDownloader implements ServerDownloader {
  final Map<MCVersion, String> _cachedBuilds = {};
  final Directory _cacheDir;
  final Logger _logger;
  final bool verbose;

  VanillaDownloader _vanillaDownloader;
  List<File> _cachedDownloads;

  PaperDownloader(this._cacheDir, {this.verbose = false})
      : _logger = Logger(verbose) {
    _vanillaDownloader = VanillaDownloader(_cacheDir, verbose: verbose);
    _cachedDownloads = _cacheDir.listSync();
  }

  @override
  Future<void> download(MCVersion version, Directory outDir) async {
    if (_cachedBuilds[version] == null) {
      _cachedBuilds[version] = await getLatestBuild(version);
    }

    final build = _cachedBuilds[version];
    final fileName = 'paper-$version-$build.jar';

    _logger.log('Downloading $fileName...');

    final cachedDownload = _cachedDownloads.firstWhere(
        (cachedDownload) => p.basename(cachedDownload.path) == fileName,
        orElse: () => null);

    if (cachedDownload != null) {
      _logger.log('Already downloaded $fileName, using cache');
      await cachedDownload.copy(p.join(outDir.path, fileName));
    } else {
      final response = await http
          .get('https://papermc.io/api/v1/paper/$version/$build/download');
      final cacheFile = await File(p.join(_cacheDir.path, fileName))
          .writeAsBytes(response.bodyBytes);
      _cachedDownloads.add(cacheFile);
      await cacheFile.copy(p.join(outDir.path, fileName));
    }
    _logger.log('Done downloading $fileName');

    await _vanillaDownloader.download(version, outDir);
  }

  static Future<String> getLatestBuild(MCVersion version) async {
    final response =
        await http.get('https://papermc.io/api/v1/paper/$version/latest');
    return jsonDecode(response.body)['build'];
  }
}
