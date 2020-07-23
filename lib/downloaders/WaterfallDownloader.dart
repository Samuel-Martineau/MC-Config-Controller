import 'dart:convert';
import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/downloaders/ServerDownloader.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

class WaterfallDownloader implements ServerDownloader {
  final Map<MCVersion, String> _cachedBuilds = {};
  final Directory _cacheDir;
  final bool verbose;

  List<File> _cachedDownloads;

  Logger _logger;

  WaterfallDownloader(this._cacheDir, {this.verbose = false}) {
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
    final cacheFileName = 'waterfall-$version-$build.jar';
    final fileName = 'server.jar';

    _logger.i('Downloading $cacheFileName...');

    final cachedDownload = _cachedDownloads.firstWhere(
        (cachedDownload) => p.basename(cachedDownload.path) == cacheFileName,
        orElse: () => null);

    if (cachedDownload != null) {
      _logger.i('Already downloaded $cacheFileName, using cache');
      await cachedDownload.copy(p.join(outDir.path, fileName));
    } else {
      try {
        final response = await http.get(
            'https://papermc.io/api/v1/waterfall/$version/$build/download');
        final cacheFile = await File(p.join(_cacheDir.path, cacheFileName))
            .writeAsBytes(response.bodyBytes);
        _cachedDownloads.add(cacheFile);
        await cacheFile.copy(p.join(outDir.path, fileName));
      } catch (e) {
        final error = e as SocketException;
        _logger.e(error.message, 'Could not reach the Waterfall website');
        exit(1);
      }
    }
    _logger.i('Done downloading $cacheFileName');
  }

  static Future<String> getLatestBuild(MCVersion version) async {
    final logger = LoggerProvider.logger;
    logger.v('Fetching the latest Waterfall build...');
    try {
      final response =
          await http.get('https://papermc.io/api/v1/waterfall/$version/latest');
      return jsonDecode(response.body)['build'];
    } catch (e) {
      final error = e as SocketException;
      logger.e(error.message, 'Could not reach the Waterfall website');
      exit(1);
    }
  }
}
