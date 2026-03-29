import 'package:board_game_library/data/dao/play_session_dao.dart';
import 'package:board_game_library/data/dao/play_session_expansion_dao.dart';
import 'package:board_game_library/data/dao/play_session_score_dao.dart';
import 'package:board_game_library/data/dao/player_dao.dart';
import 'package:board_game_library/data/repository/play_session_repository.dart';
import 'package:board_game_library/models/play_session.dart';
import 'package:board_game_library/models/play_session_details.dart';
import 'package:board_game_library/models/play_session_score.dart';
import 'package:board_game_library/models/player.dart';
import 'package:sqflite/sqflite.dart';

class SqlPlaySessionRepository extends PlaySessionRepository {
  final PlaySessionDAO _playSessionDAO;
  final PlaySessionExpansionDAO _playSessionExpansionDAO;
  final PlaySessionScoreDAO _playSessionScoreDAO;
  final PlayerDAO _playerDAO;

  SqlPlaySessionRepository(
    this._playSessionDAO,
    this._playSessionExpansionDAO,
    this._playSessionScoreDAO,
    this._playerDAO,
  );

  @override
  Future<void> deletePlaySession(PlaySession playSession) {
    return _playSessionDAO.deletePlaySession(playSession.id);
  }

  @override
  Future<List<PlaySession>> getAllPlaySessions() {
    return _playSessionDAO.getAllPlaySessions();
  }

  @override
  Future<PlaySession?> getPlaySessionById(int sessionId) {
    return _playSessionDAO.getPlaySessionById(sessionId);
  }

  @override
  Future<List<PlaySession>> getPlaySessionsForGame(int bggId) {
    return _playSessionDAO.getPlaySessionsForGame(bggId);
  }

  @override
  Future<int> countSessionsForGame(int bggId) {
    return _playSessionDAO.countSessionsForGame(bggId);
  }

  @override
  Future<int> countSessionsForExpansion(int expansionId) {
    return _playSessionExpansionDAO.countSessionsForExpansion(expansionId);
  }

  @override
  Future<List<int>> getExpansionIdsForSession(int playSessionId) {
    return _playSessionExpansionDAO.getExpansionIdsForSession(playSessionId);
  }

  @override
  Future<List<Player>> getPlayersForSession(int sessionId) {
    return _playerDAO.getPlayersForSession(sessionId);
  }

  @override
  Future<List<Player>> getAllPlayers() {
    return _playerDAO.getAllPlayers();
  }

  @override
  Future<PlaySessionScore?> getScoreForSessionPlayer(
    int playSessionId,
    int playerId,
  ) {
    return _playSessionScoreDAO.getScoreForSessionPlayer(
      playSessionId,
      playerId,
    );
  }

  @override
  Future<List<PlaySessionScore>> getScoresForSession(int playSessionId) {
    return _playSessionScoreDAO.getScoresForSession(playSessionId);
  }

  @override
  Future<void> insertPlaySession(PlaySession playSession) async {
    await _playSessionDAO.insertPlaySession(playSession);
  }

  @override
  Future<void> insertPlaySessionScore(PlaySessionScore score) async {
    await _playSessionScoreDAO.insertSessionScore(score);
  }

  @override
  Future<void> updatePlaySession(PlaySession playSession) async {
    await _playSessionDAO.updatePlaySession(playSession);
  }

  @override
  Future<PlaySessionDetails> persistSessionDetails(
    PlaySessionDetails details,
  ) async {
    if (details.scores.isEmpty) {
      if (details.session.id <= 0) {
        throw ArgumentError(
          'At least one player score is required to create a session.',
        );
      }

      await _playSessionDAO.runInTransaction((txn) async {
        await _playSessionScoreDAO.deleteScoresForSessionInTransaction(
          txn,
          details.session.id,
        );
        await _playSessionDAO.deletePlaySessionInTransaction(
          txn,
          details.session.id,
        );
      });

      return details;
    }

    return _playSessionDAO.runInTransaction((txn) async {
      final isNewSession = details.session.id <= 0;
      final sessionId = isNewSession
          ? await _playSessionDAO.insertPlaySessionInTransaction(
              txn,
              details.session,
            )
          : details.session.id;

      if (!isNewSession) {
        await _playSessionDAO.updatePlaySessionInTransaction(
          txn,
          details.session,
        );
      }

      final normalizedScores = <PlaySessionScore>[];
      for (final score in details.scores) {
        final resolvedPlayerId = await _resolvePlayerIdInTransaction(
          txn,
          score,
        );

        normalizedScores.add(
          score.copyWith(playSessionId: sessionId, playerId: resolvedPlayerId),
        );
      }

      _validateNoDuplicatePlayers(normalizedScores);

      await _playSessionScoreDAO.replaceScoresForSessionInTransaction(
        txn,
        sessionId,
        normalizedScores,
      );

      await _playSessionExpansionDAO.replaceExpansionsForSessionInTransaction(
        txn,
        sessionId,
        details.expansionIds,
      );

      return details.copyWith(
        session: details.session.copyWith(id: sessionId),
        scores: normalizedScores,
        expansionIds: details.expansionIds
            .where((id) => id > 0)
            .toSet()
            .toList(),
      );
    });
  }

  Future<int> _resolvePlayerIdInTransaction(
    Transaction txn,
    PlaySessionScore score,
  ) async {
    if (score.playerId > 0) {
      return score.playerId;
    }

    final draftPlayer = score.player;
    if (draftPlayer == null) {
      throw ArgumentError(
        'Score is missing both a persisted player id and a player payload.',
      );
    }

    if (draftPlayer.id != null && draftPlayer.id! > 0) {
      return draftPlayer.id!;
    }

    final normalizedName = draftPlayer.name.trim().toLowerCase();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Player name cannot be empty.');
    }

    final existing = await _playerDAO.findPlayerByNormalizedNameInTransaction(
      txn,
      normalizedName,
    );
    if (existing?.id != null) {
      return existing!.id!;
    }

    return _playerDAO.addPlayerInTransaction(
      txn,
      draftPlayer.copyWith(name: draftPlayer.name.trim()),
    );
  }

  void _validateNoDuplicatePlayers(List<PlaySessionScore> scores) {
    final playerIds = <int>{};
    for (final score in scores) {
      if (!playerIds.add(score.playerId)) {
        throw ArgumentError(
          'Duplicate players are not allowed in a play session.',
        );
      }
    }
  }
}
