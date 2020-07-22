import 'dart:convert';
import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/downloaders/ServerDownloader.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class WaterfallDownloader implements ServerDownloader {
  final Map<MCVersion, String> _cachedBuilds = {};
  final Directory _cacheDir;
  final bool verbose;
  final Logger _logger;

  List<File> _cachedDownloads;

  WaterfallDownloader(this._cacheDir, {this.verbose = false})
      : _logger = Logger(verbose) {
    _cachedDownloads =
        _cacheDir.listSync().map((file) => File(file.path)).toList();
  }

  @override
  Future<void> download(MCVersion version, Directory outDir) async {
    if (_cachedBuilds[version] == null) {
      _cachedBuilds[version] = await getLatestBuild(version);
    }

    final build = _cachedBuilds[version];
    final cacheFileName = 'waterfall-$version-$build.jar';
    final fileName = 'server.jar';

    _logger.log('Downloading $cacheFileName...');

    final cachedDownload = _cachedDownloads.firstWhere(
        (cachedDownload) => p.basename(cachedDownload.path) == cacheFileName,
        orElse: () => null);

    if (cachedDownload != null) {
      _logger.log('Already downloaded $cacheFileName, using cache');
      await cachedDownload.copy(p.join(outDir.path, fileName));
    } else {
      final response = await http
          .get('https://papermc.io/api/v1/waterfall/$version/$build/download');
      final cacheFile = await File(p.join(_cacheDir.path, cacheFileName))
          .writeAsBytes(response.bodyBytes);
      _cachedDownloads.add(cacheFile);
      await cacheFile.copy(p.join(outDir.path, fileName));
    }
    _logger.log('Done downloading $cacheFileName');
  }

  static Future<String> getLatestBuild(MCVersion version) async {
    final response =
        await http.get('https://papermc.io/api/v1/waterfall/$version/latest');
    return jsonDecode(response.body)['build'];
  }
}
