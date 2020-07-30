import 'dart:convert';
import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/downloaders/ServerDownloader.dart';
import 'package:Config_Controller/downloaders/VanillaDownloader.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

class PaperDownloader implements ServerDownloader {
  final Map<MCVersion, String> _cachedBuilds = {};
  final Directory _cacheDir;
  final bool verbose;

  Logger _logger;

  VanillaDownloader _vanillaDownloader;
  List<File> _cachedDownloads;

  PaperDownloader(this._cacheDir, {this.verbose = false}) {
    _vanillaDownloader = VanillaDownloader(_cacheDir, verbose: verbose);
    _cachedDownloads =
        _cacheDir.listSync().map((file) => File(file.path)).toList();
    _logger = LoggerProvider.logger;
  }

  @override
  Future<void> download(MCVersion version, Directory outDir) async {
    if (_cachedBuilds[version] == null) {
      _cachedBuilds[version] = await getLatestBuild(version);
    }

    final build = _cachedBuilds[version];
    final cacheFileName = 'paper-$version-$build.jar';
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
        final response = await http
            .get('https://papermc.io/api/v1/paper/$version/$build/download');
        final cacheFile = await File(p.join(_cacheDir.path, cacheFileName))
            .writeAsBytes(response.bodyBytes);
        _cachedDownloads.add(cacheFile);
        await cacheFile.copy(p.join(outDir.path, fileName));
      } on SocketException catch (e) {
        _logger.e(e.message, 'Could not reach the Paper website');
        _logger.d(e);
        exit(1);
      }
    }
    _logger.i('Done downloading $cacheFileName');

    await _vanillaDownloader.download(version, outDir);
  }

  static Future<String> getLatestBuild(MCVersion version) async {
    final logger = LoggerProvider.logger;
    logger.v('Fetching the latest Paper build...');
    try {
      final response =
          await http.get('https://papermc.io/api/v1/paper/$version/latest');
      return jsonDecode(response.body)['build'];
    } on SocketException catch (e) {
      logger.e(e.message, 'Could not reach the Paper website');
      logger.d(e);
      exit(1);
    }
  }
}
