import 'package:board_game_library/data/dao/play_session_dao.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/models/play_session.dart';
import 'package:sqflite/sqflite.dart';

class SqlPlaySessionDAO extends PlaySessionDAO {
  final DatabaseHelper _dbHelper;

  SqlPlaySessionDAO(this._dbHelper);

  @override
  Future<List<PlaySession>> getAllPlaySessions() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'play_sessions',
      orderBy: 'date_played DESC',
    );
    return results.map(PlaySession.fromMap).toList(growable: false);
  }

  @override
  Future<List<PlaySession>> getPlaySessionsForGame(int bggId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'play_sessions',
      where: 'board_game_id = ?',
      whereArgs: [bggId],
      orderBy: 'date_played DESC',
    );
    return results.map(PlaySession.fromMap).toList(growable: false);
  }

  @override
  Future<int> countSessionsForGame(int bggId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM play_sessions WHERE board_game_id = ?',
      [bggId],
    );
    final count = result.first['count'];
    if (count is int) {
      return count;
    }
    if (count is num) {
      return count.toInt();
    }
    return 0;
  }

  @override
  Future<PlaySession?> getPlaySessionById(int sessionId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'play_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return results.isEmpty ? null : PlaySession.fromMap(results.first);
  }

  @override
  Future<int> insertPlaySession(PlaySession session) async {
    final db = await _dbHelper.database;
    return db.insert('play_sessions', _toInsertMap(session));
  }

  @override
  Future<int> updatePlaySession(PlaySession session) async {
    final db = await _dbHelper.database;
    return db.update(
      'play_sessions',
      _toInsertMap(session),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  @override
  Future<void> deletePlaySession(int sessionId) async {
    final db = await _dbHelper.database;
    await db.delete('play_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  @override
  Future<int> insertPlaySessionInTransaction(
    Transaction txn,
    PlaySession session,
  ) {
    return txn.insert('play_sessions', _toInsertMap(session));
  }

  @override
  Future<int> updatePlaySessionInTransaction(
    Transaction txn,
    PlaySession session,
  ) {
    return txn.update(
      'play_sessions',
      _toInsertMap(session),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  @override
  Future<void> deletePlaySessionInTransaction(
    Transaction txn,
    int sessionId,
  ) async {
    await txn.delete('play_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await _dbHelper.database;
    return db.transaction(action);
  }

  Map<String, dynamic> _toInsertMap(PlaySession session) {
    return {
      'board_game_id': session.boardGameId,
      'date_played': session.datePlayed.toIso8601String(),
    };
  }
}
