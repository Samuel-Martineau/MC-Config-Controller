import 'dart:convert';

import 'package:yamlicious/yamlicious.dart';

class ConfigSerializer {
  static String serializeYAML(Map<String, Object> content) {
    return toYamlString(content);
  }

  static String serializeJSON(Map<String, Object> content) {
    return jsonEncode(content);
  }

  static String serializeProperties(Map<String, Object> content) {
    return content.entries.map((e) => '${e.key}=${e.value}').join('\n');
  }
}
