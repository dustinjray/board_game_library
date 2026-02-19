class BoardGameCategory {
  final int id;
  final String name;

  BoardGameCategory({
    required this.id,
    required this.name,
  });

  /// Converts BoardGameCategory to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  /// Creates a BoardGameCategory from a database Map
  factory BoardGameCategory.fromMap(Map<String, dynamic> map) {
    return BoardGameCategory(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
}
