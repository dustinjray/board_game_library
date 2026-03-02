import 'package:board_game_library/data/dao/expansions_dao.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:sqflite/sqflite.dart';

class SqlExpansionsDAO extends ExpansionsDAO {
	final DatabaseHelper _dbHelper;

	SqlExpansionsDAO(this._dbHelper);

	@override
	Future<int> insertExpansion(BoardGameExpansion expansion) async {
		final db = await _dbHelper.database;
		return await db.insert(
			'expansions',
			expansion.toMap(),
			conflictAlgorithm: ConflictAlgorithm.rollback,
		);
	}

	@override
	Future<void> persistExpansionsInTransaction(
		Transaction txn,
		int bggId,
		List<BoardGameExpansion> expansions,
	) async {
		await _insertExpansionsInTransaction(txn, expansions);

		final expansionIds = expansions.map((e) => e.id).toSet();
		await _deleteExpansionsForGameInTransaction(
			txn: txn,
			bggId: bggId,
			expansionIdsToKeep: expansionIds,
		);

		await _addExpansionsToGameInTransaction(txn, bggId, expansions);
	}

	Future<void> _insertExpansionsInTransaction(
		Transaction txn,
		List<BoardGameExpansion> expansions,
	) async {
		for (final expansion in expansions) {
			await txn.insert(
				'expansions',
				expansion.toMap(),
				conflictAlgorithm: ConflictAlgorithm.ignore,
			);
		}
	}

	Future<void> _addExpansionsToGameInTransaction(
		Transaction txn,
		int bggId,
		List<BoardGameExpansion> expansions,
	) async {
		for (final expansion in expansions) {
			await txn.insert(
				'board_game_expansions',
				{
					'board_game_id': bggId,
					'expansion_id': expansion.id,
				},
				conflictAlgorithm: ConflictAlgorithm.ignore,
			);
		}
	}

	@override
	Future<int> updateExpansion(BoardGameExpansion expansion) async {
		final db = await _dbHelper.database;
		return await db.update(
			'expansions',
			expansion.toMap(),
			where: 'id = ?',
			whereArgs: [expansion.id],
		);
	}

	@override
	Future<void> deleteExpansion(int expansionId) async {
		final db = await _dbHelper.database;
		await db.delete(
			'expansions',
			where: 'id = ?',
			whereArgs: [expansionId],
		);
	}

  @override
  Future<BoardGameExpansion?> getExpansionById(int expansionId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expansions',
      where: 'id = ?',
      whereArgs: [expansionId],
    );

    if (maps.isNotEmpty) {
      return BoardGameExpansion.fromMap(maps.first);
    } else {
      return null; // No expansion found with the given ID
    }
  }

	@override
	Future<List<BoardGameExpansion>> getExpansionsForGame(int bggId) async {
		final db = await _dbHelper.database;
		final List<Map<String, dynamic>> maps = await db.rawQuery('''
			SELECT e.id, e.name FROM expansions e
			INNER JOIN board_game_expansions bge ON e.id = bge.expansion_id
			WHERE bge.board_game_id = ?
		''', [bggId]);

		return List.generate(maps.length, (i) {
			return BoardGameExpansion.fromMap(maps[i]);
		});
	}

	@override
	Future<List<BoardGameExpansion>> getAllExpansions() async {
		final db = await _dbHelper.database;
		final List<Map<String, dynamic>> maps = await db.query('expansions');

		return List.generate(maps.length, (i) {
			return BoardGameExpansion.fromMap(maps[i]);
		});
	}

	@override
	Future<List<BoardGameExpansion>> getAllOwnedGameExpansions() async {
		final db = await _dbHelper.database;
		final List<Map<String, dynamic>> maps = await db.rawQuery('''
			SELECT DISTINCT e.id, e.name FROM expansions e
			INNER JOIN board_game_expansions bge ON e.id = bge.expansion_id
			INNER JOIN board_games bg ON bge.board_game_id = bg.bgg_id
			WHERE bg.is_owned = 1
		''');

		return List.generate(maps.length, (i) {
			return BoardGameExpansion.fromMap(maps[i]);
		});
	}

	Future<void> _deleteExpansionsForGameInTransaction({
		required Transaction txn,
		required int bggId,
		Set<int> expansionIdsToKeep = const {},
	}) async {
		final whereClause = expansionIdsToKeep.isEmpty
				? 'board_game_id = ?'
				: 'board_game_id = ? AND expansion_id NOT IN (${List.filled(expansionIdsToKeep.length, '?').join(',')})';
		final whereArgs = expansionIdsToKeep.isEmpty
				? [bggId]
				: [bggId, ...expansionIdsToKeep];
		await txn.delete(
			'board_game_expansions',
			where: whereClause,
			whereArgs: whereArgs,
		);
	}
}