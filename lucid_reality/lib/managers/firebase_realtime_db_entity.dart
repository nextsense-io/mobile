extension QueryBuilder on String {
  String where(String value) {
    return '$this/$value';
  }
}

class FirebaseRealtimeDBEntity<T extends Enum> {
  final Map<String, dynamic> _values = <String, dynamic>{};

  Map<String, dynamic> getValues() {
    return _values;
  }

  setValues(Map<String, dynamic> values) {
    _values.clear();
    _values.addAll(values);
  }

  dynamic getValue(T enumKey) {
    return getValues()[enumKey.name];
  }

  void setValue(T enumKey, dynamic value) {
    getValues()[enumKey.name] = value;
  }
}
