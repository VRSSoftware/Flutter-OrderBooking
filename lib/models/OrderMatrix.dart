class OrderMatrix {
  final List<String> shades;
  final List<String> sizes;
  final List<List<String>> matrix; // Each cell will store "mrp,wsp"

  OrderMatrix({
    required this.shades,
    required this.sizes,
    required this.matrix,
  });

  factory OrderMatrix.fromJson(Map<String, dynamic> json) {
    return OrderMatrix(
      shades: List<String>.from(json['shades']),
      sizes: List<String>.from(json['sizes']),
      matrix: List<List<String>>.from(
        json['matrix'].map((row) => List<String>.from(row)).toList(),
      ),
    );
  }



}
extension NullOrEmpty on Object? {
  bool get isNullOrEmpty {
    if (this == null) return true;
    if (this is String) return (this as String).isEmpty;
    if (this is List) return (this as List).isEmpty;
    if (this is Map) return (this as Map).isEmpty;
    return false;
  }
  
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}
