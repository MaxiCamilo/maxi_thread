mixin ThreadEntity {
  static dynamic _entity;

  static T? getEntity<T>() {
    if (_entity == null) {
      return null;
    }

    if (_entity is T) {
      return _entity;
    } else {
      return null;
    }
  }

  static void defineEntity(dynamic item) {
    _entity = item;
  }
}
