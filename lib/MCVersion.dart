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

  bool isGreaterThan(MCVersion toCompare) {
    return (major > toCompare.major) ||
        (major == toCompare.major && minor > toCompare.minor) ||
        (major == toCompare.major &&
            minor == toCompare.minor &&
            patch > toCompare.patch);
  }

  bool isSmallerThan(MCVersion toCompare) {
    return (major < toCompare.major) ||
        (major == toCompare.major && minor < toCompare.minor) ||
        (major == toCompare.major &&
            minor == toCompare.minor &&
            patch < toCompare.patch);
  }

  @override
  String toString() {
    return '$major.$minor' + (patch != null ? '.$patch' : '');
  }

  @override
  bool operator ==(other) {
    return toString() == other.toString();
  }
}
