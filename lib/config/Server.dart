import 'dart:io';

import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/config/Template.dart';
import 'package:path/path.dart' as p;

enum ServerType { Paper, Waterfall, Forge }

class Server extends Template {
  final ServerType type;
  final MCVersion version;
  final Map variables;

  const Server({
    String id,
    String name,
    this.type,
    this.version,
    List<String> extendsTemplates,
    List<String> keepFiles,
    this.variables,
  }) : super(
          id: id,
          name: name,
          extendsTemplates: extendsTemplates,
          keepFiles: keepFiles,
        );

  Directory getDir(Directory serversDir) {
    return Directory(p.join(serversDir.path, id));
  }

  Map toMap() {
    final possibleTypes = {
      ServerType.Paper: 'paper',
      ServerType.Waterfall: 'waterfall',
      ServerType.Forge: 'forge'
    };
    final map = {
      'id': id,
      'name': name,
      'type': possibleTypes[type],
      'version': version.toString(),
      'extends': extendsTemplates,
      'variables': variables
    };
    return map;
  }
}
