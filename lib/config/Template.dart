import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:path/path.dart' as p;

class Template {
  final String id;
  final String name;
  final List<String> extendsTemplates;
  final List<String> keepFiles;

  const Template({
    this.id,
    this.name,
    this.extendsTemplates,
    this.keepFiles,
  });

  Directory getConfigDir(Directory configDir) {
    return Directory(
        p.join(configDir.path, runtimeType.toString().toLowerCase() + 's', id));
  }

  List<Template> getFlattenExtendsTree(
    List<Template> allTemplates, [
    List<Template> alreadyTraversed,
  ]) {
    final logger = LoggerProvider.logger;

    // ignore: omit_local_variable_types
    final List<Template> flattenTree = [];
    alreadyTraversed ??= [];
    alreadyTraversed.add(this);

    extendsTemplates.forEach((templateName) {
      try {
        final template = allTemplates.firstWhere((t) => t.name == templateName);

        if (alreadyTraversed.contains(template)) {
          logger.e('Circular dependency in $this');
          exit(1);
        }
        flattenTree.addAll(
          template.getFlattenExtendsTree(allTemplates, alreadyTraversed),
        );
      } on StateError catch (e) {
        logger.e('Unresolved dependency "$templateName" in $this');
        exit(1);
      }
    });

    return [...flattenTree, this];
  }

  @override
  String toString() {
    return '${runtimeType} "$name" (ID: $id)';
  }
}
