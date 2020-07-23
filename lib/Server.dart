import 'dart:io';

import 'package:Config_Controller/MCVersion.dart';
import 'package:path/path.dart' as p;

enum ServerType { Paper, Waterfall, Forge }

class Server {
  final String id;
  final String name;
  final ServerType type;
  final MCVersion version;
  final List<String> extendsTemplates;
  final bool restricted;
  final int port;
  final int javaVersion;

  const Server({
    this.id,
    this.name,
    this.type,
    this.version,
    this.extendsTemplates,
    this.restricted,
    this.port,
    this.javaVersion,
  });

  Directory getDir(Directory serversDir) {
    return Directory(p.join(serversDir.path, id));
  }
}
