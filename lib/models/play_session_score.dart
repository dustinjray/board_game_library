import 'package:board_game_library/util/parsing.dart';
import 'package:board_game_library/util/optional.dart';
import 'package:board_game_library/models/player.dart';

class PlaySessionScore {
  final int playSessionId;
  final int playerId;
  final int? score;
  final bool isWinner;
  final Player? player;

  const PlaySessionScore({
    required this.playSessionId,
    required this.playerId,
    this.score,
    this.isWinner = false,
    this.player,
  });

  bool get hasScore => score != null;

  String get scoreInputValue => score?.toString() ?? '';

  String? get scoreSummaryLabel => score?.toString();

  Map<String, dynamic> toMap() {
    return {
      'play_session_id': playSessionId,
      'player_id': playerId,
      'score': score,
      'is_winner': isWinner ? 1 : 0,
    };
  }

  factory PlaySessionScore.fromMap(Map<String, dynamic> map) {
    return PlaySessionScore(
      playSessionId: Parsing.toInt(map['play_session_id']) ?? 0,
      playerId: Parsing.toInt(map['player_id']) ?? 0,
      score: Parsing.toInt(map['score']),
      isWinner: Parsing.toBool(map['is_winner']),
      player: null,
    );
  }

  PlaySessionScore copyWith({
    int? playSessionId,
    int? playerId,
    Optional<int?> score = const Optional.absent(),
    bool? isWinner,
    Player? player,
  }) {
    return PlaySessionScore(
      playSessionId: playSessionId ?? this.playSessionId,
      playerId: playerId ?? this.playerId,
      score: score.isPresent ? score.value : this.score,
      isWinner: isWinner ?? this.isWinner,
      player: player ?? this.player,
    );
  }

  static int? parseScoreInput(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();
    if (normalized.isEmpty || normalized.toUpperCase() == 'N/A') {
      return null;
    }

    return int.tryParse(normalized);
  }
}
