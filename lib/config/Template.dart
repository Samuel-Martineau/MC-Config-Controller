import 'dart:io';

import 'package:Config_Controller/config/Server.dart';
import 'package:path/path.dart' as p;

class Template {
  final String id;
  final String name;
  final List<String> extendsTemplates;

  const Template({
    this.id,
    this.name,
    this.extendsTemplates,
  });

  Directory getConfigDir(Directory configDir) {
    return Directory(p.join(configDir.path, id));
  }

  Directory getDir(Directory serversDir) {
    return Directory(p.join(serversDir.path, id));
  }

  List<Template> getFlattenExtendsTree(
      List<Server> serverList, List<Template> templateList) {}
}
