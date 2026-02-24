import 'package:board_game_library/models/player.dart';

class PlaySession {
  final int id;
  final int boardGameId;
  final DateTime date;
  int? winnerId;
  final List<Player> players;

  PlaySession({
    required this.id,
    required this.boardGameId,
    required this.date,
    this.winnerId,
    this.players = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'board_game_id': boardGameId,
      'date_played': date.toIso8601String(),
      'winner_id': winnerId,
    };
  }

  factory PlaySession.fromMap(Map<String, dynamic> map) {
    return PlaySession(
      id: _toInt(map['id']) ?? 0,
      boardGameId: _toInt(map['boardGameId'] ?? map['board_game_id']) ?? 0,
      date: _toDateTime(map['date'] ?? map['date_played']) ?? DateTime.now(),
      winnerId: _toInt(map['winnerId'] ?? map['winner_id']),
    );
  }

  PlaySession copyWith({
    int? id,
    int? boardGameId,
    DateTime? date,
    int? winnerId,
    List<Player>? players,
  }) {
    return PlaySession(
      id: id ?? this.id,
      boardGameId: boardGameId ?? this.boardGameId,
      date: date ?? this.date,
      winnerId: winnerId ?? this.winnerId,
      players: players ?? this.players,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}
