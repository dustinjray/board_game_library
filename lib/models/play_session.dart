class PlaySession {
  final int id;
  final int boardGameId;
  final DateTime datePlayed;

  PlaySession({
    required this.id,
    required this.boardGameId,
    required this.datePlayed,
  });

  PlaySession copyWith({
    int? id,
    int? boardGameId,
    DateTime? datePlayed,
  }) {
    return PlaySession(
      id: id ?? this.id,
      boardGameId: boardGameId ?? this.boardGameId,
      datePlayed: datePlayed ?? this.datePlayed,
    );
  }

  PlaySession.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        boardGameId = map['board_game_id'],
        datePlayed = DateTime.parse(map['date_played']);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'board_game_id': boardGameId,
      'date_played': datePlayed.toIso8601String(),
    };
  }

}