class BoardGameExpansion {
  final int id;
  final String name;

  BoardGameExpansion({
    required this.id,
    required this.name,
  });

  /// Converts BoardGameExpansion to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  /// Creates a BoardGameExpansion from a database Map
  factory BoardGameExpansion.fromMap(Map<String, dynamic> map) {
    return BoardGameExpansion(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
}
