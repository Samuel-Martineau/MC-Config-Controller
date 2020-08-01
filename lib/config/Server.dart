import 'dart:io';

import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/config/Template.dart';
import 'package:json_schema/json_schema.dart';
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
    List<String> removeFiles,
    this.variables,
  }) : super(
          id: id,
          name: name,
          extendsTemplates: extendsTemplates,
          keepFiles: keepFiles,
          removeFiles: removeFiles,
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

  static JsonSchema schema = JsonSchema.createSchema(r'''
  {
    "$schema": "http://json-schema.org/draft-06/schema#",
    "$id": "http://example.com/example.json",
    "type": "object",
    "required": [
      "name",
      "type",
      "version",
      "extends",
      "keepFiles",
      "removeFiles",
      "variables"
    ],
    "properties": {
      "name": {
        "$id": "#/properties/name",
        "type": "string"
      },
      "type": {
        "enum": [
          "forge",
          "paper",
          "waterfall"
        ]
      },
      "version": {
        "pattern": "^\\d+\\.\\d+(.\\d+)?$"
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
      },
      "variables": {
        "additionalProperties": true
      }
    },
    "additionalProperties": false
  }
  ''');
}
