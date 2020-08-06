import 'dart:convert';

import 'package:liquid_engine/liquid_engine.dart' as liquid_engine;
import 'package:quiver/iterables.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

class ConfigParser {
  static String parseVars(String content, Map variables) {
    final context = liquid_engine.Context.create();
    context.variables = variables;
    final uuid = Uuid().v1();
    return partition(content.split('\n'), 50)
        .map((lines) {
          final chunk =
              ['chunk_start_$uuid', ...lines, 'chunk_end_$uuid'].join('\n');
          final template = liquid_engine.Template.parse(
              context, liquid_engine.Source.fromString(chunk));
          return template.render(context);
        })
        .join('\n')
        .replaceAll(RegExp('chunk_(start|end)_$uuid(\n)?'), '');
  }

  static Map<dynamic, dynamic> parseYAML(String content) {
    return loadYaml(content);
  }

  static dynamic parseJSON(String content) {
    return jsonDecode(content);
  }

  static Map<dynamic, dynamic> parseProperties(String content) {
    final regex = RegExp(r'^([\w-.]+) ?= ?(.*)$');
    final object = {};
    content
        .split('\n')
        .map((line) => regex.firstMatch(line))
        .where((element) => element != null)
        .forEach((match) => object[match.group(1)] = match.group(2));
    return object;
  }
}
