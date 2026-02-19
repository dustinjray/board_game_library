class BoardGameMechanic {
  final int id;
  final String name;

  BoardGameMechanic({
    required this.id,
    required this.name,
  });

  /// Converts BoardGameMechanic to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  /// Creates a BoardGameMechanic from a database Map
  factory BoardGameMechanic.fromMap(Map<String, dynamic> map) {
    return BoardGameMechanic(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
}
