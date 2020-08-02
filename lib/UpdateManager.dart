import 'dart:convert';
import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:Config_Controller/environment_config.dart';
import 'package:http/http.dart' as http;

class UpdateManager {
  static void printUpdateMessage() async {
    final currentRelease = UpdateManager.currentVersion;
    final latestRelease = await UpdateManager.latestVersion;

    if (currentRelease != latestRelease) {
      LoggerProvider.logger.i("""
MC-Config-Controller isn't up to date
You're using v$currentRelease and the latest version is v$latestRelease
Consider downloading the latest version here => https://github.com/Samuel-Martineau/MC-Config-Controller/releases/latest
      """
          .trim());
    }
  }

  static Future<String> get latestVersion async {
    try {
      final response = await http.get(
          'https://api.github.com/repos/Samuel-Martineau/MC-Config-Controller/releases/latest');
      final parsed = jsonDecode(response.body);
      return parsed['tag_name'];
    } catch (e) {
      LoggerProvider.logger
          .e('Unable to fetch latest version... Are you offline ?');
      exit(1);
    }
  }

  static String get currentVersion {
    return EnvironmentConfig.build_version;
  }
}
