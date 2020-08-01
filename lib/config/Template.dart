import 'dart:io';

import 'package:Config_Controller/Logger.dart';
import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;

class Template {
  final String id;
  final String name;
  final List<String> extendsTemplates;
  final List<String> keepFiles;
  final List<String> removeFiles;

  const Template({
    this.id,
    this.name,
    this.extendsTemplates,
    this.keepFiles,
    this.removeFiles,
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
        logger.d(e);
        exit(1);
      }
    });

    return [...flattenTree, this];
  }

  @override
  String toString() {
    return '${runtimeType} "$name" (ID: $id)';
  }

  static JsonSchema schema = JsonSchema.createSchema(r'''
  {
    "$schema": "http://json-schema.org/draft-06/schema#",
    "$id": "http://example.com/example.json",
    "type": "object",
    "required": [
      "name",
      "extends",
      "keepFiles",
      "removeFiles"
    ],
    "properties": {
      "name": {
        "$id": "#/properties/name",
        "type": "string"
    	},
      "extends": {
        "$id": "#/properties/extends",
        "type": "array",
        "additionalItems": true,
        "items": {
          "type": "string"
        }
      },
      "keepFiles": {
        "$id": "#/properties/keepFiles",
        "type": "array",
        "additionalItems": true,
        "items": {
          "type": "string"
        }
      },
      "removeFiles": {
        "$id": "#/properties/removeFiles",
        "type": "array",
        "additionalItems": true,
        "items": {
          "type": "string"
        }
      }
    },
    "additionalProperties": false
  }
  ''');
}
