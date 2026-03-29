class Player {
  final int? id;
  final String name;

  Player({this.id, required this.name});

  Player copyWith({int? id, String? name}) {
    return Player(id: id ?? this.id, name: name ?? this.name);
  }

  Player.fromMap(Map<String, dynamic> map) : id = map['id'], name = map['name'];

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'name': name};
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
