import 'package:Config_Controller/MCVersion.dart';
import 'package:Config_Controller/config/Template.dart';

enum ServerType { Paper, Waterfall, Forge }

class Server extends Template {
  final ServerType type;
  final MCVersion version;
  final bool restricted;
  final int port;

  const Server({
    String id,
    String name,
    this.type,
    this.version,
    List<String> extendsTemplates,
    this.restricted,
    this.port,
  }) : super(id: id, name: name, extendsTemplates: extendsTemplates);
}
