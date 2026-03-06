import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:flutter/services.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static String? _databasePathOverride;

  static void setDatabasePathOverrideForTesting(String? path) {
    if (_database != null && _database!.isOpen) {
      throw StateError(
        'Cannot change database path while database is open. Call close() first.',
      );
    }
    _databasePathOverride = path;
  }

  Future<String> loadSql(String path) async {
    return await rootBundle.loadString(path);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path =
        _databasePathOverride ??
        join(await getDatabasesPath(), 'board_games_database.db');
    print('Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        final createTablesSql = await loadSql('assets/sql/create_tables.sql');
        final statements = createTablesSql.split(';');
        for (var statement in statements) {
          if (statement.trim().isNotEmpty) {
            await db.execute(statement);
            print('Executed SQL statement: $statement');
          }
        }
      },
      onOpen: (db) async {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_board_games_name_nocase ON board_games(name COLLATE NOCASE)',
        );
      },
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _database = null;
  }

  // Future<int> insertBoardGame(BoardGame game) async {
  //   final db = await database;
  //   return await db.insert(
  //     'board_games',
  //     game.toMap(),
  //     conflictAlgorithm: ConflictAlgorithm.ignore,
  //   );
  // }

  // Future<int> getBoardGameCount() async {
  //   final db = await database;
  //   final result = await db.rawQuery(
  //     'SELECT COUNT(*) AS count FROM board_games',
  //   );
  //   final value = result.first['count'];
  //   if (value is int) {
  //     return value;
  //   }
  //   if (value is num) {
  //     return value.toInt();
  //   }
  //   return int.tryParse(value?.toString() ?? '') ?? 0;
  // }

  // Future<int> pruneExpansionGamesTemporarily() async {
  //   final db = await database;
  //   await db.delete('board_games', where: 'is_expansion = ?', whereArgs: [1]);
  //   return getBoardGameCount();
  // }

  // Future<void> insertBoardGamesBulk(
  //   List<BoardGame> games, {
  //   int chunkSize = 2000,
  // }) async {
  //   final db = await database;

  //   for (var start = 0; start < games.length; start += chunkSize) {
  //     final end = (start + chunkSize < games.length)
  //         ? start + chunkSize
  //         : games.length;
  //     final chunk = games.sublist(start, end);

  //     await db.transaction((txn) async {
  //       final batch = txn.batch();
  //       for (final game in chunk) {
  //         batch.insert(
  //           'board_games',
  //           game.toMap(),
  //           conflictAlgorithm: ConflictAlgorithm.ignore,
  //         );
  //       }
  //       await batch.commit(noResult: true);
  //     });
  //   }
  // }

// This method will be moved to the repository layer, leaving it here for now until then.
  // Future<void> insertBoardGameWithRelations(BoardGame game) async {
  //   final db = await database;
  //   await db.transaction((txn) async {
  //     await txn.insert(
  //       'board_games',
  //       game.toMap(),
  //       conflictAlgorithm: ConflictAlgorithm.ignore,
  //     );
  //     await _insertCategories(txn, game.bggId, game.categories);
  //     await _insertMechanics(txn, game.bggId, game.mechanics);
  //     await _insertExpansions(txn, game.bggId, game.expansions);
  //   });
  // }

  // Future<int> updateBoardGame(BoardGame game) async {
  //   final db = await database;
  //   return await db.update(
  //     'board_games',
  //     game.toMap(),
  //     where: 'bgg_id = ?',
  //     whereArgs: [game.bggId],
  //   );
  // }

// This method will be moved to the repository layer, leaving it here for now until then.
  // Future<void> updateBoardGameWithRelations(BoardGame game) async {
  //   final existing = await getBoardGameById(game.bggId);
  //   if (existing == null) {
  //     throw ArgumentError(
  //       'Cannot update non-existent game with bgg_id=${game.bggId}',
  //     );
  //   }
  //   final db = await database;
  //   await db.transaction((txn) async {
  //     await txn.update(
  //       'board_games',
  //       game.toMap(),
  //       where: 'bgg_id = ?',
  //       whereArgs: [game.bggId],
  //     );
  //     await _syncGameCategories(txn, game.bggId, game.categories);
  //     await _syncGameMechanics(txn, game.bggId, game.mechanics);
  //     await _syncGameExpansions(txn, game.bggId, game.expansions);
  //   });
  // }

  // Future<int> deleteBoardGame(int bggId) async {
  //   final db = await database;
  //   return await db.delete(
  //     'board_games',
  //     where: 'bgg_id = ?',
  //     whereArgs: [bggId],
  //   );
  // }

  // Future<List<BoardGame>> getAllBoardGames() async {
  //   final db = await database;
  //   final List<Map<String, dynamic>> maps = await db.query(
  //     'board_games',
  //     orderBy: 'name ASC',
  //   );

  //   return List.generate(maps.length, (i) {
  //     return BoardGame.fromMap(maps[i]);
  //   });
  // }

  // Future<BoardGame?> getBoardGameById(int bggId) async {
  //   final db = await database;
  //   final List<Map<String, dynamic>> maps = await db.query(
  //     'board_games',
  //     where: 'bgg_id = ?',
  //     whereArgs: [bggId],
  //   );

  //   if (maps.isNotEmpty) {
  //     return BoardGame.fromMap(maps.first);
  //   } else {
  //     return null;
  //   }
  // }

// This method will be moved to the repository layer, leaving it here for now until then.
  // Future<BoardGame?> getBoardGameWithRelationsById(int bggId) async {
  //   final game = await getBoardGameById(bggId);
  //   if (game == null) {
  //     return null;
  //   }
  //   final categories = await getCategoriesForGame(bggId);
  //   final mechanics = await getMechanicsForGame(bggId);
  //   final expansions = await getExpansionsForGame(bggId);
  //   return game.copyWith(
  //     categories: categories,
  //     mechanics: mechanics,
  //     expansions: expansions,
  //   );
  // }

  // Future<List<BoardGame>> searchByCriteria(BoardGameCriteria criteria) async {
  //   final db = await database;

  //   String sql = 'SELECT * FROM board_games WHERE 1=1';
  //   final args = <dynamic>[];

  //   if (criteria.minPlayers != null) {
  //     sql += ' AND min_players <= ?';
  //     args.add(criteria.minPlayers);
  //   }

  //   if (criteria.maxPlayers != null) {
  //     sql += ' AND max_players >= ?';
  //     args.add(criteria.maxPlayers);
  //   }

  //   if (criteria.minPlaytime != null) {
  //     sql += ' AND min_playtime >= ?';
  //     args.add(criteria.minPlaytime);
  //   }

  //   if (criteria.maxPlaytime != null) {
  //     sql += ' AND max_playtime <= ?';
  //     args.add(criteria.maxPlaytime);
  //   }

  //   if (criteria.age != null) {
  //     sql += ' AND age <= ?';
  //     args.add(criteria.age);
  //   }

  //   if (criteria.nameLike != null) {
  //     sql += ' AND name LIKE ?';
  //     args.add('%${criteria.nameLike}%');
  //   }

  //   if (criteria.isFavorite != null) {
  //     if (criteria.isFavorite!) {
  //       sql += ' AND is_favorite = 1';
  //     } else {
  //       sql += ' AND is_favorite = 0';
  //     }
  //   }

  //   if (criteria.isExpansion != null) {
  //     if (criteria.isExpansion!) {
  //       sql += ' AND is_expansion = 1';
  //     } else {
  //       sql += ' AND is_expansion = 0';
  //     }
  //   }

  //   if (criteria.isUnplayed != null) {
  //     if (criteria.isUnplayed!) {
  //       sql += ' AND times_played = 0';
  //     } else {
  //       sql += ' AND times_played > 0';
  //     }
  //   }

  //   if (criteria.isOwned != null) {
  //     if (criteria.isOwned!) {
  //       sql += ' AND is_owned = 1';
  //     } else {
  //       sql += ' AND is_owned = 0';
  //     }
  //   }

  //   if (criteria.categories != null && criteria.categories!.isNotEmpty) {
  //     final categoryIds = criteria.categories!.map((c) => c.id).join(',');
  //     sql +=
  //         ' AND bgg_id IN (SELECT board_game_id FROM board_game_categories WHERE category_id IN ($categoryIds))';
  //   }

  //   if (criteria.mechanics != null && criteria.mechanics!.isNotEmpty) {
  //     final mechanicIds = criteria.mechanics!.map((m) => m.id).join(',');
  //     sql +=
  //         ' AND bgg_id IN (SELECT board_game_id FROM board_game_mechanics WHERE mechanic_id IN ($mechanicIds))';
  //   }

  //   sql += ' ORDER BY name ASC';

  //   final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);

  //   return List.generate(maps.length, (i) {
  //     return BoardGame.fromMap(maps[i]);
  //   });
  // }

  // Board Game Mechanics CRUD operations

//   Future<int> _insertMechanic(
//     Transaction txn,
//     BoardGameMechanic mechanic,
//   ) async {
//     return await txn.insert(
//       'mechanics',
//       mechanic.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.ignore,
//     );
//   }

//   Future<int> deleteMechanic(int id) async {
//     final db = await database;
//     return await db.delete('mechanics', where: 'id = ?', whereArgs: [id]);
//   }

//   Future<List<BoardGameMechanic>> getAllMechanics() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query('mechanics');

//     return List.generate(maps.length, (i) {
//       return BoardGameMechanic.fromMap(maps[i]);
//     });
//   }

//   Future<BoardGameMechanic?> getMechanicById(int id) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'mechanics',
//       where: 'id = ?',
//       whereArgs: [id],
//     );

//     if (maps.isNotEmpty) {
//       return BoardGameMechanic.fromMap(maps.first);
//     } else {
//       return null;
//     }
//   }

//   Future<int> _addMechanicToGame(
//     Transaction txn,
//     int bggId,
//     int mechanicId,
//   ) async {
//     return await txn.insert('board_game_mechanics', {
//       'board_game_id': bggId,
//       'mechanic_id': mechanicId,
//     }, conflictAlgorithm: ConflictAlgorithm.ignore);
//   }

//   Future<void> _insertMechanics(
//     Transaction txn,
//     int bggId,
//     List<BoardGameMechanic> mechanics,
//   ) async {
//     for (var mechanic in mechanics) {
//       await _insertMechanic(txn, mechanic);
//       await _addMechanicToGame(txn, bggId, mechanic.id);
//     }
//   }

//   Future<List<BoardGameMechanic>> getMechanicsForGame(int bggId) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.rawQuery(
//       '''
//       SELECT m.id, m.name
//       FROM mechanics m
//       JOIN board_game_mechanics bgm ON m.id = bgm.mechanic_id
//       WHERE bgm.board_game_id = ?
//       ORDER BY m.name ASC
//     ''',
//       [bggId],
//     );

//     return List.generate(maps.length, (i) {
//       return BoardGameMechanic.fromMap(maps[i]);
//     });
//   }

//   Future<List<BoardGameMechanic>> getOwnedMechanics() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.rawQuery('''
//       SELECT DISTINCT m.id, m.name
//       FROM mechanics m
//       JOIN board_game_mechanics bgm ON m.id = bgm.mechanic_id
//       JOIN board_games bg ON bgm.board_game_id = bg.bgg_id
//       WHERE bg.is_owned = 1
//       ORDER BY m.name ASC
//     ''');
//     if (maps.isEmpty) {
//       return [];
//     } else {
//       return List.generate(maps.length, (i) {
//         return BoardGameMechanic.fromMap(maps[i]);
//       });
//     }
//   }

//   Future<void> _syncGameMechanics(
//     Transaction txn,
//     int bggId,
//     List<BoardGameMechanic> mechanics,
//   ) async {
//     final desiredMechanicIds = mechanics.map((m) => m.id).toSet();
//     final existingRows = await txn.query(
//       'board_game_mechanics',
//       columns: ['mechanic_id'],
//       where: 'board_game_id = ?',
//       whereArgs: [bggId],
//     );
//     final existingMechanicIds = existingRows
//         .map((row) => (row['mechanic_id'] as num).toInt())
//         .toSet();

//     final toAdd = desiredMechanicIds.difference(existingMechanicIds);
//     final toRemove = existingMechanicIds.difference(desiredMechanicIds);
//     final mechanicsById = {
//       for (final mechanic in mechanics) mechanic.id: mechanic,
//     };

//     if (toRemove.isNotEmpty) {
//       final placeholders = List.filled(toRemove.length, '?').join(',');
//       await txn.delete(
//         'board_game_mechanics',
//         where: 'board_game_id = ? AND mechanic_id IN ($placeholders)',
//         whereArgs: [bggId, ...toRemove],
//       );
//     }

//     if (toAdd.isNotEmpty) {
//       for (final mechanicId in toAdd) {
//         final mechanic = mechanicsById[mechanicId];
//         if (mechanic != null) {
//           await _insertMechanic(txn, mechanic);
//           await _addMechanicToGame(txn, bggId, mechanicId);
//         }
//       }
//     }
//   }

//   // Board Game Categories CRUD operations

//   Future<int> _insertCategory(
//     Transaction txn,
//     BoardGameCategory category,
//   ) async {
//     return await txn.insert(
//       'categories',
//       category.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.ignore,
//     );
//   }

//   Future<int> deleteCategory(int id) async {
//     final db = await database;
//     return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
//   }

//   Future<List<BoardGameCategory>> getAllCategories() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'categories',
//       orderBy: 'name ASC',
//     );

//     return List.generate(maps.length, (i) {
//       return BoardGameCategory.fromMap(maps[i]);
//     });
//   }

//   Future<BoardGameCategory?> getCategoryById(int id) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'categories',
//       where: 'id = ?',
//       whereArgs: [id],
//     );

//     if (maps.isNotEmpty) {
//       return BoardGameCategory.fromMap(maps.first);
//     } else {
//       return null;
//     }
//   }

//   Future<int> _addCategoryToGame(
//     Transaction txn,
//     int bggId,
//     int categoryId,
//   ) async {
//     return await txn.insert('board_game_categories', {
//       'board_game_id': bggId,
//       'category_id': categoryId,
//     }, conflictAlgorithm: ConflictAlgorithm.ignore);
//   }

//   Future<void> _insertCategories(
//     Transaction txn,
//     int bggId,
//     List<BoardGameCategory> categories,
//   ) async {
//     for (var category in categories) {
//       await _insertCategory(txn, category);
//       await _addCategoryToGame(txn, bggId, category.id);
//     }
//   }

//   Future<List<BoardGameCategory>> getCategoriesForGame(int bggId) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.rawQuery(
//       '''
//       SELECT c.id, c.name
//       FROM categories c
//       JOIN board_game_categories bgc ON c.id = bgc.category_id
//       WHERE bgc.board_game_id = ?
//       ORDER BY c.name ASC
//     ''',
//       [bggId],
//     );

//     return List.generate(maps.length, (i) {
//       return BoardGameCategory.fromMap(maps[i]);
//     });
//   }

//   Future<List<BoardGameCategory>> getOwnedCategories() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.rawQuery('''
//       SELECT DISTINCT c.id, c.name
//       FROM categories c
//       JOIN board_game_categories bgc ON c.id = bgc.category_id
//       JOIN board_games bg ON bgc.board_game_id = bg.bgg_id
//       WHERE bg.is_owned = 1
//       ORDER BY c.name ASC
//     ''');
//     if (maps.isEmpty) {
//       return [];
//     } else {
//       return List.generate(maps.length, (i) {
//         return BoardGameCategory.fromMap(maps[i]);
//       });
//     }
//   }

//   Future<void> _syncGameCategories(
//     Transaction txn,
//     int bggId,
//     List<BoardGameCategory> categories,
//   ) async {
//     final desiredCategoryIds = categories.map((c) => c.id).toSet();
//     final existingRows = await txn.query(
//       'board_game_categories',
//       columns: ['category_id'],
//       where: 'board_game_id = ?',
//       whereArgs: [bggId],
//     );
//     final existingCategoryIds = existingRows
//         .map((row) => (row['category_id'] as num).toInt())
//         .toSet();

//     final toAdd = desiredCategoryIds.difference(existingCategoryIds);
//     final toRemove = existingCategoryIds.difference(desiredCategoryIds);
//     final categoriesById = {
//       for (final category in categories) category.id: category,
//     };

//     if (toRemove.isNotEmpty) {
//       final placeholders = List.filled(toRemove.length, '?').join(',');
//       await txn.delete(
//         'board_game_categories',
//         where: 'board_game_id = ? AND category_id IN ($placeholders)',
//         whereArgs: [bggId, ...toRemove],
//       );
//     }

//     if (toAdd.isNotEmpty) {
//       for (final categoryId in toAdd) {
//         final category = categoriesById[categoryId];
//         if (category != null) {
//           await _insertCategory(txn, category);
//           await _addCategoryToGame(txn, bggId, categoryId);
//         }
//       }
//     }
//   }

//   // Board Game Expansions CRUD operations

//   Future<int> _insertExpansion(
//     Transaction txn,
//     BoardGameExpansion expansion,
//   ) async {
//     return await txn.insert(
//       'expansions',
//       expansion.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.ignore,
//     );
//   }

//   Future<int> deleteExpansion(int id) async {
//     final db = await database;
//     return await db.delete('expansions', where: 'id = ?', whereArgs: [id]);
//   }

//   Future<List<BoardGameExpansion>> getAllExpansions() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query('expansions');

//     return List.generate(maps.length, (i) {
//       return BoardGameExpansion.fromMap(maps[i]);
//     });
//   }

//   Future<BoardGameExpansion?> getExpansionById(int id) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'expansions',
//       where: 'id = ?',
//       whereArgs: [id],
//     );

//     if (maps.isNotEmpty) {
//       return BoardGameExpansion.fromMap(maps.first);
//     } else {
//       return null;
//     }
//   }

//   Future<int> _addExpansionToGame(
//     Transaction txn,
//     int bggId,
//     int expansionId,
//   ) async {
//     return await txn.insert('board_game_expansions', {
//       'board_game_id': bggId,
//       'expansion_id': expansionId,
//     }, conflictAlgorithm: ConflictAlgorithm.ignore);
//   }

//   Future<void> _insertExpansions(
//     Transaction txn,
//     int bggId,
//     List<BoardGameExpansion> expansions,
//   ) async {
//     for (var expansion in expansions) {
//       await _insertExpansion(txn, expansion);
//       await _addExpansionToGame(txn, bggId, expansion.id);
//     }
//   }

//   Future<List<BoardGameExpansion>> getExpansionsForGame(int bggId) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.rawQuery(
//       '''
//       SELECT e.id, e.name
//       FROM expansions e
//       JOIN board_game_expansions bge ON e.id = bge.expansion_id
//       WHERE bge.board_game_id = ?
//       ORDER BY e.name ASC
//     ''',
//       [bggId],
//     );

//     return List.generate(maps.length, (i) {
//       return BoardGameExpansion.fromMap(maps[i]);
//     });
//   }

//   Future<void> _syncGameExpansions(
//     Transaction txn,
//     int bggId,
//     List<BoardGameExpansion> expansions,
//   ) async {
//     final desiredExpansionIds = expansions.map((e) => e.id).toSet();
//     final existingRows = await txn.query(
//       'board_game_expansions',
//       columns: ['expansion_id'],
//       where: 'board_game_id = ?',
//       whereArgs: [bggId],
//     );
//     final existingExpansionIds = existingRows
//         .map((row) => (row['expansion_id'] as num).toInt())
//         .toSet();

//     final toAdd = desiredExpansionIds.difference(existingExpansionIds);
//     final toRemove = existingExpansionIds.difference(desiredExpansionIds);
//     final expansionsById = {
//       for (final expansion in expansions) expansion.id: expansion,
//     };

//     if (toRemove.isNotEmpty) {
//       final placeholders = List.filled(toRemove.length, '?').join(',');
//       await txn.delete(
//         'board_game_expansions',
//         where: 'board_game_id = ? AND expansion_id IN ($placeholders)',
//         whereArgs: [bggId, ...toRemove],
//       );
//     }

//     if (toAdd.isNotEmpty) {
//       for (final expansionId in toAdd) {
//         final expansion = expansionsById[expansionId];
//         if (expansion != null) {
//           await _insertExpansion(txn, expansion);
//           await _addExpansionToGame(txn, bggId, expansionId);
//         }
//       }
//     }
//   }
// }
}
