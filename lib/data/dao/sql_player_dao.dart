import 'package:board_game_library/data/dao/player_dao.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/models/player.dart';
import 'package:sqflite/sqflite.dart';

class SqlPlayerDAO extends PlayerDAO {
  final DatabaseHelper _dbHelper;

  SqlPlayerDAO(this._dbHelper);

  @override
  Future<List<Player>> getAllPlayers() async {
    final db = await _dbHelper.database;
    final results = await db.query('players', orderBy: 'name ASC');
    return results.map(Player.fromMap).toList(growable: false);
  }

  @override
  Future<Player> getPlayerById(int playerId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'players',
      where: 'id = ?',
      whereArgs: [playerId],
      limit: 1,
    );
    if (results.isEmpty) {
      throw Exception('Player not found with id $playerId');
    }

    return Player.fromMap(results.first);
  }

  @override
  Future<List<Player>> getPlayersForSession(int sessionId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      '''
      SELECT p.id, p.name
      FROM players p
      INNER JOIN play_session_scores ps ON p.id = ps.player_id
      WHERE ps.play_session_id = ?
      ORDER BY p.name ASC
    ''',
      [sessionId],
    );

    return results.map(Player.fromMap).toList(growable: false);
  }

  @override
  Future<int> addPlayer(Player player) async {
    await _ensureNoDuplicateName(player);

    final db = await _dbHelper.database;
    return db.insert(
      'players',
      player.copyWith(name: player.name.trim()).toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<int> addPlayerInTransaction(Transaction txn, Player player) async {
    await _ensureNoDuplicateNameInTransaction(txn, player);

    return txn.insert(
      'players',
      player.copyWith(name: player.name.trim()).toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<int> updatePlayer(Player player) async {
    if (player.id == null) {
      throw ArgumentError('Cannot update player without id.');
    }

    await _ensureNoDuplicateName(player);

    final db = await _dbHelper.database;
    return db.update(
      'players',
      player.copyWith(name: player.name.trim()).toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  @override
  Future<void> deletePlayer(int playerId) async {
    final db = await _dbHelper.database;
    await db.delete('players', where: 'id = ?', whereArgs: [playerId]);
  }

  @override
  Future<Player?> findPlayerByNormalizedName(String normalizedName) async {
    final db = await _dbHelper.database;
    final normalized = _normalizeName(normalizedName);
    if (normalized.isEmpty) {
      return null;
    }

    final results = await db.query(
      'players',
      where: 'LOWER(TRIM(name)) = ?',
      whereArgs: [normalized],
      limit: 1,
    );

    return results.isEmpty ? null : Player.fromMap(results.first);
  }

  @override
  Future<Player?> findPlayerByNormalizedNameInTransaction(
    Transaction txn,
    String normalizedName,
  ) async {
    final normalized = _normalizeName(normalizedName);
    if (normalized.isEmpty) {
      return null;
    }

    final results = await txn.query(
      'players',
      where: 'LOWER(TRIM(name)) = ?',
      whereArgs: [normalized],
      limit: 1,
    );

    return results.isEmpty ? null : Player.fromMap(results.first);
  }

  String _normalizeName(String value) => value.trim().toLowerCase();

  Future<void> _ensureNoDuplicateName(Player player) async {
    final normalized = _normalizeName(player.name);
    if (normalized.isEmpty) {
      throw ArgumentError('Player name cannot be empty.');
    }

    final existing = await findPlayerByNormalizedName(normalized);
    if (existing != null && existing.id != player.id) {
      throw StateError(
        'A player named "${player.name.trim()}" already exists.',
      );
    }
  }

  Future<void> _ensureNoDuplicateNameInTransaction(
    Transaction txn,
    Player player,
  ) async {
    final normalized = _normalizeName(player.name);
    if (normalized.isEmpty) {
      throw ArgumentError('Player name cannot be empty.');
    }

    final existing = await findPlayerByNormalizedNameInTransaction(
      txn,
      normalized,
    );
    if (existing != null && existing.id != player.id) {
      throw StateError(
        'A player named "${player.name.trim()}" already exists.',
      );
    }
  }
}
