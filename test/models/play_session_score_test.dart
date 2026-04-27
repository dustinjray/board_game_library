import 'package:board_game_library/models/play_session_score.dart';
import 'package:board_game_library/models/player.dart';
import 'package:board_game_library/util/optional.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaySessionScore.fromMap', () {
    test('coerces map values correctly', () {
      final score = PlaySessionScore.fromMap({
        'play_session_id': '7',
        'player_id': 8,
        'score': '42',
        'is_winner': 1,
      });

      expect(score.playSessionId, 7);
      expect(score.playerId, 8);
      expect(score.score, 42);
      expect(score.isWinner, isTrue);
      expect(score.player, isNull);
    });
  });

  group('PlaySessionScore.copyWith Optional score behavior', () {
    test('keeps existing score when Optional.absent is used', () {
      const original = PlaySessionScore(
        playSessionId: 1,
        playerId: 2,
        score: 10,
        isWinner: false,
      );

      final updated = original.copyWith(isWinner: true);

      expect(updated.score, 10);
      expect(updated.isWinner, isTrue);
    });

    test('sets score to null when Optional.of(null) is provided', () {
      const original = PlaySessionScore(
        playSessionId: 1,
        playerId: 2,
        score: 10,
      );

      final updated = original.copyWith(score: const Optional<int?>.of(null));

      expect(updated.score, isNull);
    });

    test('replaces score when Optional.of(value) is provided', () {
      const original = PlaySessionScore(
        playSessionId: 1,
        playerId: 2,
        score: 10,
      );

      final updated = original.copyWith(score: const Optional<int?>.of(25));

      expect(updated.score, 25);
    });
  });

  group('PlaySessionScore.parseScoreInput', () {
    test('returns null for null, blank, and N/A values', () {
      expect(PlaySessionScore.parseScoreInput(null), isNull);
      expect(PlaySessionScore.parseScoreInput(''), isNull);
      expect(PlaySessionScore.parseScoreInput('  '), isNull);
      expect(PlaySessionScore.parseScoreInput('N/A'), isNull);
      expect(PlaySessionScore.parseScoreInput(' n/a '), isNull);
    });

    test('parses valid integers and rejects invalid strings', () {
      expect(PlaySessionScore.parseScoreInput('17'), 17);
      expect(PlaySessionScore.parseScoreInput(' 9 '), 9);
      expect(PlaySessionScore.parseScoreInput('abc'), isNull);
    });
  });

  group('PlaySessionScore helper getters', () {
    test('score helpers reflect score presence', () {
      const withScore = PlaySessionScore(playSessionId: 1, playerId: 2, score: 11);
      const withoutScore = PlaySessionScore(playSessionId: 1, playerId: 2);

      expect(withScore.hasScore, isTrue);
      expect(withScore.scoreInputValue, '11');
      expect(withScore.scoreSummaryLabel, '11');

      expect(withoutScore.hasScore, isFalse);
      expect(withoutScore.scoreInputValue, '');
      expect(withoutScore.scoreSummaryLabel, isNull);
    });

    test('copyWith can update player payload', () {
      const original = PlaySessionScore(playSessionId: 1, playerId: 2);
      final updated = original.copyWith(player: Player(id: 2, name: 'Alex'));

      expect(updated.player, isNotNull);
      expect(updated.player!.name, 'Alex');
    });
  });
}
