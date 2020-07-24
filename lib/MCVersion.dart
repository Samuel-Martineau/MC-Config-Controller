class MCVersion {
  int major;
  int minor;
  int patch;

  MCVersion(String v) {
    final splitted = v.split('.');
    major = int.parse(splitted[0]);
    minor = int.parse(splitted[1]);
    if (splitted.length == 3) patch = int.parse(splitted[2]);
  }

  @override
  String toString() {
    return '$major.$minor' + (patch != null ? '.$patch' : '');
  }

  @override
  bool operator ==(other) {
    return other is MCVersion && toString() == other.toString();
  }

  // @override
  // bool operator >(MCVersion other) {}

  // @override
  // bool operator <(MCVersion other) {}

  // @override
  // bool operator >=(MCVersion other) {}

  // @override
  // bool operator <=(MCVersion other) {}
}
