import 'package:board_game_library/data/dao/play_session_expansion_dao.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class SqlPlaySessionExpansionDAO extends PlaySessionExpansionDAO {
  final DatabaseHelper _dbHelper;

  SqlPlaySessionExpansionDAO(this._dbHelper);

  @override
  Future<List<int>> getExpansionIdsForSession(int playSessionId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'play_session_expansions',
      columns: ['expansion_id'],
      where: 'play_session_id = ?',
      whereArgs: [playSessionId],
      orderBy: 'expansion_id ASC',
    );

    return rows
        .map((row) => row['expansion_id'])
        .whereType<int>()
        .toList(growable: false);
  }

  @override
  Future<List<int>> getSessionIdsForExpansion(int expansionId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'play_session_expansions',
      columns: ['play_session_id'],
      where: 'expansion_id = ?',
      whereArgs: [expansionId],
      orderBy: 'play_session_id DESC',
    );

    return rows
        .map((row) => row['play_session_id'])
        .whereType<int>()
        .toList(growable: false);
  }

  @override
  Future<int> linkExpansionToSession(int playSessionId, int expansionId) async {
    final db = await _dbHelper.database;
    return db.insert('play_session_expansions', {
      'play_session_id': playSessionId,
      'expansion_id': expansionId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<int> unlinkExpansionFromSession(
    int playSessionId,
    int expansionId,
  ) async {
    final db = await _dbHelper.database;
    return db.delete(
      'play_session_expansions',
      where: 'play_session_id = ? AND expansion_id = ?',
      whereArgs: [playSessionId, expansionId],
    );
  }

  @override
  Future<int> deleteLinksForSession(int playSessionId) async {
    final db = await _dbHelper.database;
    return db.delete(
      'play_session_expansions',
      where: 'play_session_id = ?',
      whereArgs: [playSessionId],
    );
  }

  @override
  Future<int> countSessionsForExpansion(int expansionId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM play_session_expansions WHERE expansion_id = ?',
      [expansionId],
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
  Future<void> replaceExpansionsForSessionInTransaction(
    Transaction txn,
    int playSessionId,
    List<int> expansionIds,
  ) async {
    await txn.delete(
      'play_session_expansions',
      where: 'play_session_id = ?',
      whereArgs: [playSessionId],
    );

    final normalizedIds = expansionIds.where((id) => id > 0).toSet();
    for (final expansionId in normalizedIds) {
      await txn.insert('play_session_expansions', {
        'play_session_id': playSessionId,
        'expansion_id': expansionId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
