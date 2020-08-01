import 'dart:convert';

import 'package:liquid_engine/liquid_engine.dart' as liquid_engine;
import 'package:yaml/yaml.dart';

class ConfigParser {
  static String parseVars(String content, Map variables) {
    final context = liquid_engine.Context.create();
    context.variables = variables;
    final template = liquid_engine.Template.parse(
        context, liquid_engine.Source.fromString(content));
    return template.render(context);
    // return Template(content).renderString(variables);
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
        .forEach((match) => object[match.group(1)] = object[match.group(2)]);
    return object;
  }
}
