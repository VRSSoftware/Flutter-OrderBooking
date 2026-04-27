class KeyName {
  final String key;
  final String name;
  final Map<String, dynamic>? extra;
  final bool isMissing;

  KeyName({
    required this.key, 
    required this.name,
    this.extra,
    this.isMissing = false,
  });

  factory KeyName.fromJson(Map<String, dynamic> json) {
    return KeyName(
      key: json['ledKey']?.toString() ?? '',
      name: json['ledName']?.toString() ?? '',
      extra: json,
      isMissing: false,
    );
  }

  // Factory for creating a "missing" KeyName
  factory KeyName.missing(String key, String name) {
    return KeyName(
      key: key,
      name: name,
      extra: null,
      isMissing: true,
    );
  }

  String? get salesLedKey => extra?['salesLedKey']?.toString();
}