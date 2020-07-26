import 'dart:convert';

import 'package:yamlicious/yamlicious.dart';

class ConfigSerializer {
  static String serializeYAML(Map<dynamic, dynamic> content) {
    return toYamlString(content);
  }

  static String serializeJSON(Map<dynamic, dynamic> content) {
    return jsonEncode(content);
  }

  static String serializeProperties(Map<dynamic, dynamic> content) {
    return content.entries.map((e) => '${e.key}=${e.value}').join('\n');
  }
}
