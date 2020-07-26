import 'dart:io';

import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/config/Template.dart';
import 'package:path/path.dart' as p;

enum ServerType { Paper, Waterfall, Forge }

class Server extends Template {
  final ServerType type;
  final MCVersion version;
  final bool restricted;
  final int port;

  const Server({
    String id,
    String name,
    this.type,
    this.version,
    List<String> extendsTemplates,
    this.restricted,
    this.port,
  }) : super(id: id, name: name, extendsTemplates: extendsTemplates);

  Directory getDir(Directory serversDir) {
    return Directory(p.join(serversDir.path, id));
  }

  Map toMap() {
    final map = {
      'id': id,
      'name': name,
      'type': type,
      'version': version.toString(),
      'extends': extendsTemplates,
      'restricted': restricted,
      'port': port
    };
    return map;
  }
}
