import 'dart:convert';

import 'package:mustache_template/mustache.dart';
import 'package:yaml/yaml.dart';

class ConfigParser {
  static String parseVars(String content, Map variables) {
    return Template(content).renderString(variables);
  }

  static Map<dynamic, dynamic> parseYAML(String content) {
    return loadYaml(content);
  }

  static Map<dynamic, dynamic> parseJSON(String content) {
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
