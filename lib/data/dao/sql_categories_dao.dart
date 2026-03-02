import 'package:board_game_library/data/dao/categories_dao.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:sqflite/sqflite.dart';

class SqlCategoriesDAO extends CategoriesDAO {
	final DatabaseHelper _dbHelper;

	SqlCategoriesDAO(this._dbHelper);

	@override
	Future<int> insertCategory(BoardGameCategory category) async {
		final db = await _dbHelper.database;
		return await db.insert(
			'categories',
			category.toMap(),
			conflictAlgorithm: ConflictAlgorithm.rollback,
		);
	}

	@override
	Future<void> persistCategoriesInTransaction(
		Transaction txn,
		int bggId,
		List<BoardGameCategory> categories,
	) async {
		await _insertCategoriesInTransaction(txn, categories);

		final categoryIds = categories.map((c) => c.id).toSet();
		await _deleteCategoriesForGameInTransaction(
			txn: txn,
			bggId: bggId,
			categoryIdsToKeep: categoryIds,
		);

		await _addCategoriesToGameInTransaction(txn, bggId, categories);
	}

	Future<void> _insertCategoriesInTransaction(
		Transaction txn,
		List<BoardGameCategory> categories,
	) async {
		for (final category in categories) {
			await txn.insert(
				'categories',
				category.toMap(),
				conflictAlgorithm: ConflictAlgorithm.ignore,
			);
		}
	}

	Future<void> _addCategoriesToGameInTransaction(
		Transaction txn,
		int bggId,
		List<BoardGameCategory> categories,
	) async {
		for (final category in categories) {
			await txn.insert(
				'board_game_categories',
				{
					'board_game_id': bggId,
					'category_id': category.id,
				},
				conflictAlgorithm: ConflictAlgorithm.ignore,
			);
		}
	}

	@override
	Future<int> updateCategory(BoardGameCategory category) async {
		final db = await _dbHelper.database;
		return await db.update(
			'categories',
			category.toMap(),
			where: 'id = ?',
			whereArgs: [category.id],
		);
	}

	@override
	Future<void> deleteCategory(int categoryId) async {
		final db = await _dbHelper.database;
		await db.delete(
			'categories',
			where: 'id = ?',
			whereArgs: [categoryId],
		);
	}

  @override
  Future<BoardGameCategory?> getCategoryById(int categoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );

    if (maps.isNotEmpty) {
      return BoardGameCategory.fromMap(maps.first);
    } else {
      return null; // No category found with the given ID
    }
  }

	@override
	Future<List<BoardGameCategory>> getCategoriesForGame(int bggId) async {
		final db = await _dbHelper.database;
		final List<Map<String, dynamic>> maps = await db.rawQuery('''
			SELECT c.id, c.name FROM categories c
			INNER JOIN board_game_categories bgc ON c.id = bgc.category_id
			WHERE bgc.board_game_id = ?
		''', [bggId]);

		return List.generate(maps.length, (i) {
			return BoardGameCategory.fromMap(maps[i]);
		});
	}

	@override
	Future<List<BoardGameCategory>> getAllCategories() async {
		final db = await _dbHelper.database;
		final List<Map<String, dynamic>> maps = await db.query('categories');

		return List.generate(maps.length, (i) {
			return BoardGameCategory.fromMap(maps[i]);
		});
	}

	@override
	Future<List<BoardGameCategory>> getAllOwnedGameCategories() async {
		final db = await _dbHelper.database;
		final List<Map<String, dynamic>> maps = await db.rawQuery('''
			SELECT DISTINCT c.id, c.name FROM categories c
			INNER JOIN board_game_categories bgc ON c.id = bgc.category_id
			INNER JOIN board_games bg ON bgc.board_game_id = bg.bgg_id
			WHERE bg.is_owned = 1
		''');

		return List.generate(maps.length, (i) {
			return BoardGameCategory.fromMap(maps[i]);
		});
	}

	Future<void> _deleteCategoriesForGameInTransaction({
		required Transaction txn,
		required int bggId,
		Set<int> categoryIdsToKeep = const {},
	}) async {
		final whereClause = categoryIdsToKeep.isEmpty
				? 'board_game_id = ?'
				: 'board_game_id = ? AND category_id NOT IN (${List.filled(categoryIdsToKeep.length, '?').join(',')})';
		final whereArgs = categoryIdsToKeep.isEmpty
				? [bggId]
				: [bggId, ...categoryIdsToKeep];
		await txn.delete(
			'board_game_categories',
			where: whereClause,
			whereArgs: whereArgs,
		);
	}
}