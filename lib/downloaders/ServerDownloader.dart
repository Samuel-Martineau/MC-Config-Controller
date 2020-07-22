import 'dart:io';

import 'package:Config_Controller/MCVersion.dart';

abstract class ServerDownloader {
  Future<void> download(MCVersion version, Directory outDir);
}
