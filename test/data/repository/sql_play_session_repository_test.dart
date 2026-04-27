import 'package:board_game_library/data/dao/play_session_dao.dart';
import 'package:board_game_library/data/dao/play_session_expansion_dao.dart';
import 'package:board_game_library/data/dao/play_session_score_dao.dart';
import 'package:board_game_library/data/dao/player_dao.dart';
import 'package:board_game_library/data/repository/sql_play_session_repository.dart';
import 'package:board_game_library/models/play_session.dart';
import 'package:board_game_library/models/play_session_details.dart';
import 'package:board_game_library/models/play_session_score.dart';
import 'package:board_game_library/models/player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';

class _MockPlaySessionDAO extends Mock implements PlaySessionDAO {}

class _MockPlaySessionExpansionDAO extends Mock
    implements PlaySessionExpansionDAO {}

class _MockPlaySessionScoreDAO extends Mock implements PlaySessionScoreDAO {}

class _MockPlayerDAO extends Mock implements PlayerDAO {}

class _MockTransaction extends Mock implements Transaction {}

void main() {
  late _MockPlaySessionDAO playSessionDAO;
  late _MockPlaySessionExpansionDAO playSessionExpansionDAO;
  late _MockPlaySessionScoreDAO playSessionScoreDAO;
  late _MockPlayerDAO playerDAO;
  late _MockTransaction txn;
  late SqlPlaySessionRepository repository;

  setUpAll(() {
    registerFallbackValue(
      PlaySession(id: 1, boardGameId: 1, datePlayed: DateTime(2024, 1, 1)),
    );
    registerFallbackValue(const PlaySessionScore(playSessionId: 1, playerId: 1));
    registerFallbackValue(Player(id: 1, name: 'Fallback'));
    registerFallbackValue(_MockTransaction());
  });

  setUp(() {
    playSessionDAO = _MockPlaySessionDAO();
    playSessionExpansionDAO = _MockPlaySessionExpansionDAO();
    playSessionScoreDAO = _MockPlaySessionScoreDAO();
    playerDAO = _MockPlayerDAO();
    txn = _MockTransaction();

    repository = SqlPlaySessionRepository(
      playSessionDAO,
      playSessionExpansionDAO,
      playSessionScoreDAO,
      playerDAO,
    );

    when(
      () => playSessionDAO.runInTransaction<PlaySessionDetails>(any()),
    ).thenAnswer((invocation) async {
      final action = invocation.positionalArguments.first
          as Future<PlaySessionDetails> Function(Transaction);
      return action(txn);
    });

    when(() => playSessionDAO.runInTransaction<void>(any())).thenAnswer((
      invocation,
    ) async {
      final action =
          invocation.positionalArguments.first as Future<void> Function(Transaction);
      return action(txn);
    });

    when(() => playSessionDAO.runInTransaction<Null>(any())).thenAnswer((
      invocation,
    ) async {
      final action =
          invocation.positionalArguments.first as Future<Null> Function(Transaction);
      return action(txn);
    });
  });

  group('persistSessionDetails', () {
    test('throws when creating a session without scores', () async {
      final details = PlaySessionDetails(
        session: PlaySession(id: 0, boardGameId: 5, datePlayed: DateTime(2024, 1, 1)),
        scores: const [],
      );

      await expectLater(
        () => repository.persistSessionDetails(details),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deletes existing session when scores list is empty', () async {
      final details = PlaySessionDetails(
        session: PlaySession(id: 9, boardGameId: 5, datePlayed: DateTime(2024, 1, 1)),
        scores: const [],
      );

      when(
        () => playSessionScoreDAO.deleteScoresForSessionInTransaction(txn, 9),
      ).thenAnswer((_) async => 1);
      when(
        () => playSessionDAO.deletePlaySessionInTransaction(txn, 9),
      ).thenAnswer((_) async {});

      final result = await repository.persistSessionDetails(details);

      expect(result.session.id, 9);
      verify(() => playSessionScoreDAO.deleteScoresForSessionInTransaction(txn, 9)).called(1);
      verify(() => playSessionDAO.deletePlaySessionInTransaction(txn, 9)).called(1);
    });

    test('normalizes player id from existing normalized name and persists scores', () async {
      final details = PlaySessionDetails(
        session: PlaySession(id: 0, boardGameId: 7, datePlayed: DateTime(2024, 3, 1)),
        scores: [
          PlaySessionScore(
            playSessionId: 0,
            playerId: 0,
            score: 15,
            player: Player(name: ' Alice '),
          ),
        ],
        expansionIds: const [2, 3],
      );

      when(
        () => playSessionDAO.insertPlaySessionInTransaction(txn, any()),
      ).thenAnswer((_) async => 77);
      when(
        () => playerDAO.findPlayerByNormalizedNameInTransaction(txn, 'alice'),
      ).thenAnswer((_) async => Player(id: 5, name: 'Alice'));
      when(
        () => playSessionScoreDAO.replaceScoresForSessionInTransaction(
          txn,
          77,
          any(),
        ),
      ).thenAnswer((_) async {});
      when(
        () => playSessionExpansionDAO.replaceExpansionsForSessionInTransaction(
          txn,
          77,
          const [2, 3],
        ),
      ).thenAnswer((_) async {});

      final result = await repository.persistSessionDetails(details);

      final capturedScores = verify(
        () => playSessionScoreDAO.replaceScoresForSessionInTransaction(
          txn,
          77,
          captureAny(),
        ),
      ).captured.single as List<PlaySessionScore>;

      expect(result.session.id, 77);
      expect(result.scores.single.playerId, 5);
      expect(capturedScores.single.playSessionId, 77);
      expect(capturedScores.single.playerId, 5);
      verifyNever(() => playerDAO.addPlayerInTransaction(any(), any()));
    });

    test('throws on duplicate players after normalization', () async {
      final details = PlaySessionDetails(
        session: PlaySession(id: 0, boardGameId: 7, datePlayed: DateTime(2024, 3, 1)),
        scores: const [
          PlaySessionScore(playSessionId: 0, playerId: 11, score: 15),
          PlaySessionScore(playSessionId: 0, playerId: 11, score: 20),
        ],
      );

      when(
        () => playSessionDAO.insertPlaySessionInTransaction(txn, any()),
      ).thenAnswer((_) async => 55);

      await expectLater(
        () => repository.persistSessionDetails(details),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Duplicate players are not allowed'),
          ),
        ),
      );

      verifyNever(
        () => playSessionScoreDAO.replaceScoresForSessionInTransaction(
          any(),
          any(),
          any(),
        ),
      );
    });
  });
}
