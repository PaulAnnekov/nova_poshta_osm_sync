class LocationName {
  String _originalName;
  LocationName(String name) {
    _originalName = name;
  }

  LocationName.fromNP(String name) {
    var cityParts = name.split('(');
    _originalName = cityParts[0].trim();
  }

  bool operator ==(LocationName other) => this.toString() == other.toString();

  String toString() {
    return _originalName.toLowerCase().replaceAll(new RegExp("[`'\"’ -]"),'');
  }
}