import 'package:board_game_library/data/dao/mechanics_dao.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:sqflite/sqflite.dart';

class SqlMechanicsDAO extends MechanicsDAO {
  final DatabaseHelper _dbHelper;

  SqlMechanicsDAO(this._dbHelper);

  @override
  Future<int> insertMechanic(BoardGameMechanic mechanic) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'mechanics',
      mechanic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.rollback,
    );
  }

  @override
  Future<void> persistMechanicsInTransaction(Transaction txn, int bggId, List<BoardGameMechanic> mechanics) async {
    // First, insert mechanics into the mechanics table if they don't already exist
    await _insertMechanicsInTransaction(txn, mechanics);

    // Next, remove any mechanic associations for this game that are not in the new list of mechanics
    final mechanicIds = mechanics.map((m) => m.id).toSet();
    await _deleteMechanicsForGameInTransaction(txn: txn, bggId: bggId, mechanicIdsToKeep: mechanicIds);

    // Then associate the mechanics with the board game in the junction table
    await _addMechanicsToGameInTransaction(txn, bggId, mechanics);
  }

  Future<void> _insertMechanicsInTransaction(Transaction txn, List<BoardGameMechanic> mechanics) async {
    for (final mechanic in mechanics) {
      await txn.insert(
        'mechanics',
        mechanic.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _addMechanicsToGameInTransaction(Transaction txn, int bggId, List<BoardGameMechanic> mechanics) async {
    for (final mechanic in mechanics) {
      await txn.insert(
        'board_game_mechanics',
        {
          'board_game_id': bggId,
          'mechanic_id': mechanic.id,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<int> updateMechanic(BoardGameMechanic mechanic) async {
    final db = await _dbHelper.database;
    return await db.update(
      'mechanics',
      mechanic.toMap(),
      where: 'id = ?',
      whereArgs: [mechanic.id],
    );
  }

  @override
  Future<void> deleteMechanic(int mechanicId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'mechanics',
      where: 'id = ?',
      whereArgs: [mechanicId],
    );
  }

  @override
  Future<BoardGameMechanic?> getMechanicById(int mechanicId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mechanics',
      where: 'id = ?',
      whereArgs: [mechanicId],
    );

    if (maps.isNotEmpty) {
      return BoardGameMechanic.fromMap(maps.first);
    } else {
      return null;
    }
  }

  @override
  Future<List<BoardGameMechanic>> getMechanicsForGame(int bggId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT m.id, m.name FROM mechanics m
      INNER JOIN board_game_mechanics bgm ON m.id = bgm.mechanic_id
      WHERE bgm.board_game_id = ?
    ''', [bggId]);

    return List.generate(maps.length, (i) {
      return BoardGameMechanic.fromMap(maps[i]);
    });
  }

  @override
  Future<List<BoardGameMechanic>> getAllMechanics() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('mechanics');

    return List.generate(maps.length, (i) {
      return BoardGameMechanic.fromMap(maps[i]);
    });
  }

  @override
  Future<List<BoardGameMechanic>> getAllOwnedGameMechanics() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT m.id, m.name FROM mechanics m
      INNER JOIN board_game_mechanics bgm ON m.id = bgm.mechanic_id
      INNER JOIN board_games bg ON bgm.board_game_id = bg.bgg_id
      WHERE bg.is_owned = 1
    ''');

    return List.generate(maps.length, (i) {
      return BoardGameMechanic.fromMap(maps[i]);
    });
  }

  Future<void> _deleteMechanicsForGameInTransaction({required Transaction txn, required int bggId, Set<int> mechanicIdsToKeep = const {}}) async {
    final whereClause = mechanicIdsToKeep.isEmpty ? 'board_game_id = ?' : 'board_game_id = ? AND mechanic_id NOT IN (${List.filled(mechanicIdsToKeep.length, '?').join(',')})';
    final whereArgs = mechanicIdsToKeep.isEmpty ? [bggId] : [bggId, ...mechanicIdsToKeep];
    await txn.delete(
      'board_game_mechanics',
      where: whereClause,
      whereArgs: whereArgs,
    );
  }
}