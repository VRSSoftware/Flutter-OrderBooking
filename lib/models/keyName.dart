class KeyName {
  final String key;
  final String name;
  final Map<String, dynamic>? extra;  // Add this line

  KeyName({
    required this.key, 
    required this.name,
    this.extra,  // Add this line
  });
}