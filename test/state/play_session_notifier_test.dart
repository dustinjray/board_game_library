import 'package:board_game_library/data/repository/play_session_repository.dart';
import 'package:board_game_library/models/play_session.dart';
import 'package:board_game_library/models/play_session_details.dart';
import 'package:board_game_library/models/play_session_score.dart';
import 'package:board_game_library/models/player.dart';
import 'package:board_game_library/state/play_session_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlaySessionRepository extends Mock implements PlaySessionRepository {}

void main() {
  late _MockPlaySessionRepository repo;
  late PlaySessionNotifier notifier;

  setUpAll(() {
    registerFallbackValue(
      PlaySession(id: 1, boardGameId: 1, datePlayed: DateTime(2024, 1, 1)),
    );
    registerFallbackValue(
      PlaySessionDetails(
        session: PlaySession(id: 1, boardGameId: 1, datePlayed: DateTime(2024, 1, 1)),
        scores: const [],
      ),
    );
  });

  setUp(() {
    repo = _MockPlaySessionRepository();
    notifier = PlaySessionNotifier(repo);
  });

  group('loadSessionsForGame', () {
    test('hydrates sessions with scores, players, and expansion ids', () async {
      final session = PlaySession(id: 10, boardGameId: 5, datePlayed: DateTime(2024, 1, 2));
      final playerA = Player(id: 101, name: 'Alice');
      final playerB = Player(id: 102, name: 'Bob');

      when(() => repo.getPlaySessionsForGame(5)).thenAnswer((_) async => [session]);
      when(() => repo.getScoresForSession(10)).thenAnswer(
        (_) async => const [
          PlaySessionScore(playSessionId: 10, playerId: 101, score: 20),
          PlaySessionScore(playSessionId: 10, playerId: 102, score: 15),
        ],
      );
      when(() => repo.getPlayersForSession(10)).thenAnswer((_) async => [playerA, playerB]);
      when(() => repo.getExpansionIdsForSession(10)).thenAnswer((_) async => [1, 2]);

      await notifier.loadSessionsForGame(5);

      expect(notifier.isLoading, isFalse);
      expect(notifier.sessions.length, 1);
      expect(notifier.sessions.first.expansionIds, [1, 2]);
      expect(notifier.sessions.first.scores.first.player!.name, 'Alice');
      expect(notifier.sessions.first.scores.last.player!.name, 'Bob');
    });

    test('resets loading flag and keeps sessions empty when repository throws', () async {
      when(() => repo.getPlaySessionsForGame(5)).thenThrow(Exception('boom'));

      await notifier.loadSessionsForGame(5);

      expect(notifier.isLoading, isFalse);
      expect(notifier.sessions, isEmpty);
    });
  });

  group('loadAllPlayers', () {
    test('loads all players and clears loading flag', () async {
      when(() => repo.getAllPlayers()).thenAnswer(
        (_) async => [Player(id: 1, name: 'Alice')],
      );

      await notifier.loadAllPlayers();

      expect(notifier.isPlayersLoading, isFalse);
      expect(notifier.players.length, 1);
      expect(notifier.players.first.name, 'Alice');
    });

    test('clears loading flag when repository throws', () async {
      when(() => repo.getAllPlayers()).thenThrow(Exception('fail'));

      await notifier.loadAllPlayers();

      expect(notifier.isPlayersLoading, isFalse);
      expect(notifier.players, isEmpty);
    });
  });

  group('save and delete flows', () {
    test('saveSession persists details and reloads sessions', () async {
      final details = PlaySessionDetails(
        session: PlaySession(id: 1, boardGameId: 5, datePlayed: DateTime(2024, 1, 1)),
        scores: const [PlaySessionScore(playSessionId: 1, playerId: 1, score: 10)],
      );

      when(() => repo.persistSessionDetails(details)).thenAnswer((_) async => details);
      when(() => repo.getPlaySessionsForGame(5)).thenAnswer((_) async => const []);

      await notifier.saveSession(details, 5);

      verify(() => repo.persistSessionDetails(details)).called(1);
      verify(() => repo.getPlaySessionsForGame(5)).called(1);
    });

    test('deleteSession deletes and reloads sessions', () async {
      final session = PlaySession(id: 1, boardGameId: 5, datePlayed: DateTime(2024, 1, 1));

      when(() => repo.deletePlaySession(session)).thenAnswer((_) async {});
      when(() => repo.getPlaySessionsForGame(5)).thenAnswer((_) async => const []);

      await notifier.deleteSession(session, 5);

      verify(() => repo.deletePlaySession(session)).called(1);
      verify(() => repo.getPlaySessionsForGame(5)).called(1);
    });
  });
}
