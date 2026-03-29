import 'package:board_game_library/data/dao/play_session_score_dao.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/models/play_session_score.dart';
import 'package:sqflite/sqflite.dart';

class SqlPlaySessionScoreDAO extends PlaySessionScoreDAO {
  final DatabaseHelper _dbHelper;

  SqlPlaySessionScoreDAO(this._dbHelper);

  @override
  Future<List<PlaySessionScore>> getScoresForSession(int playSessionId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'play_session_scores',
      where: 'play_session_id = ?',
      whereArgs: [playSessionId],
      orderBy: 'score DESC',
    );

    return results.map(PlaySessionScore.fromMap).toList(growable: false);
  }

  @override
  Future<PlaySessionScore?> getScoreForSessionPlayer(
    int playSessionId,
    int playerId,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'play_session_scores',
      where: 'play_session_id = ? AND player_id = ?',
      whereArgs: [playSessionId, playerId],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return PlaySessionScore.fromMap(results.first);
  }

  @override
  Future<int> insertSessionScore(PlaySessionScore score) async {
    final db = await _dbHelper.database;
    return db.insert(
      'play_session_scores',
      score.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<int> insertSessionScoreInTransaction(
    Transaction txn,
    PlaySessionScore score,
  ) {
    return txn.insert(
      'play_session_scores',
      score.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<int> upsertSessionScore(PlaySessionScore score) async {
    final db = await _dbHelper.database;
    return db.insert(
      'play_session_scores',
      score.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> upsertSessionScoreInTransaction(
    Transaction txn,
    PlaySessionScore score,
  ) {
    return txn.insert(
      'play_session_scores',
      score.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateSessionScore(PlaySessionScore score) async {
    final db = await _dbHelper.database;
    return db.update(
      'play_session_scores',
      score.toMap(),
      where: 'play_session_id = ? AND player_id = ?',
      whereArgs: [score.playSessionId, score.playerId],
    );
  }

  @override
  Future<int> deleteSessionScore(int playSessionId, int playerId) async {
    final db = await _dbHelper.database;
    return db.delete(
      'play_session_scores',
      where: 'play_session_id = ? AND player_id = ?',
      whereArgs: [playSessionId, playerId],
    );
  }

  @override
  Future<int> deleteScoresForSession(int playSessionId) async {
    final db = await _dbHelper.database;
    return db.delete(
      'play_session_scores',
      where: 'play_session_id = ?',
      whereArgs: [playSessionId],
    );
  }

  @override
  Future<int> deleteScoresForSessionInTransaction(
    Transaction txn,
    int playSessionId,
  ) {
    return txn.delete(
      'play_session_scores',
      where: 'play_session_id = ?',
      whereArgs: [playSessionId],
    );
  }

  @override
  Future<void> replaceScoresForSessionInTransaction(
    Transaction txn,
    int playSessionId,
    List<PlaySessionScore> scores,
  ) async {
    await deleteScoresForSessionInTransaction(txn, playSessionId);

    for (final score in scores) {
      final normalized = score.playSessionId == playSessionId
          ? score
          : score.copyWith(playSessionId: playSessionId);
      await upsertSessionScoreInTransaction(txn, normalized);
    }
  }
}
