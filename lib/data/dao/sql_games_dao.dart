import 'package:board_game_library/data/dao/games_dao.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:sqflite/sqflite.dart';

class SqlGamesDAO extends GamesDAO {
  final DatabaseHelper _dbHelper;

  SqlGamesDAO(this._dbHelper);

  @override
  Future<int> insertBoardGame(BoardGame game) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'board_games',
      game.toMap(),
      conflictAlgorithm: ConflictAlgorithm.rollback,
    );
  }

  @override
  Future<int> insertBoardGameInTransaction(Transaction txn, BoardGame game) async {
    return await txn.insert(
      'board_games',
      game.toMap(),
      conflictAlgorithm: ConflictAlgorithm.rollback,
    );
  }

  @override
  Future<void> insertGamesBulk(List<BoardGame> games, {int chunkSize = 2000}) async {
    final db = await _dbHelper.database;

    for (var start = 0; start < games.length; start += chunkSize) {
      final end = (start + chunkSize < games.length)
          ? start + chunkSize
          : games.length;
      final chunk = games.sublist(start, end);

      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final game in chunk) {
          batch.insert(
            'board_games',
            game.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      });
    }
  }

  @override
  Future<BoardGame?> getBoardGameById(int bggId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'board_games',
      where: 'bgg_id = ?',
      whereArgs: [bggId],
    );

    if (maps.isNotEmpty) {
      return BoardGame.fromMap(maps.first);
    } else {
      return null; // No game found with the given ID
    }
  }

  @override
  Future<List<BoardGame>> getAllGames() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('board_games', orderBy: 'name ASC');
    return List.generate(maps.length, (i) {
      return BoardGame.fromMap(maps[i]);
    });
  }

  @override
  Future<List<BoardGame>> getAllBaseGames() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'board_games',
      where: 'is_expansion = 0',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) {
      return BoardGame.fromMap(maps[i]);
    });
  }

  @override
  Future<List<BoardGame>> getAllOwnedGames() {
    return searchByCriteria(BoardGameCriteria(isOwned: true));
  }

  @override
  Future<List<BoardGame>> getAllOwnedBaseGames() {
    return searchByCriteria(BoardGameCriteria(isOwned: true, isExpansion: false));
  }

  @override
  Future<List<BoardGame>> searchByCriteria(BoardGameCriteria criteria) async {
    final db = await _dbHelper.database;

    String sql = 'SELECT * FROM board_games WHERE 1=1';
    final args = <dynamic>[];

    if (criteria.minPlayers != null) {
      sql += ' AND min_players <= ?';
      args.add(criteria.minPlayers);
    }

    if (criteria.maxPlayers != null) {
      sql += ' AND max_players >= ?';
      args.add(criteria.maxPlayers);
    }

    if (criteria.maxPlaytime != null) {
      sql += ' AND max_playtime <= ?';
      args.add(criteria.maxPlaytime);
    }

    if (criteria.age != null) {
      sql += ' AND age <= ?';
      args.add(criteria.age);
    }

    if (criteria.nameLike != null) {
      sql += ' AND name LIKE ?';
      args.add('%${criteria.nameLike}%');
    }

    if (criteria.isFavorite != null) {
      if (criteria.isFavorite!) {
        sql += ' AND is_favorite = 1';
      } else {
        sql += ' AND is_favorite = 0';
      }
    }

    if (criteria.isExpansion != null) {
      if (criteria.isExpansion!) {
        sql += ' AND is_expansion = 1';
      } else {
        sql += ' AND is_expansion = 0';
      }
    }

    if (criteria.isUnplayed != null) {
      if (criteria.isUnplayed!) {
        sql += ' AND times_played = 0';
      } else {
        sql += ' AND times_played > 0';
      }
    }

    if (criteria.isOwned != null) {
      if (criteria.isOwned!) {
        sql += ' AND is_owned = 1';
      } else {
        sql += ' AND is_owned = 0';
      }
    }

    if (criteria.categories != null && criteria.categories!.isNotEmpty) {
      final categoryIds = criteria.categories!.map((c) => c.id).toList();
      final placeholders = List.filled(categoryIds.length, '?').join(',');
      sql += ' AND bgg_id IN (SELECT board_game_id FROM board_game_categories WHERE category_id IN ($placeholders))';
      args.addAll(categoryIds);
    }

    if (criteria.mechanics != null && criteria.mechanics!.isNotEmpty) {
      final mechanicIds = criteria.mechanics!.map((m) => m.id).toList();
      final placeholders = List.filled(mechanicIds.length, '?').join(',');
      sql += ' AND bgg_id IN (SELECT board_game_id FROM board_game_mechanics WHERE mechanic_id IN ($placeholders))';
      args.addAll(mechanicIds);
    }

    sql += ' ORDER BY name ASC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);

    return List.generate(maps.length, (i) {
      return BoardGame.fromMap(maps[i]);
    });
  }

  @override
  Future<int> updateBoardGame(BoardGame game) async {
    final db = await _dbHelper.database;
    return await db.update(
      'board_games',
      game.toMap(),
      where: 'bgg_id = ?',
      whereArgs: [game.bggId],
    );
  }

  @override
  Future<int> updateBoardGameInTransaction(Transaction txn, BoardGame game) async {
    return await txn.update(
      'board_games',
      game.toMap(),
      where: 'bgg_id = ?',
      whereArgs: [game.bggId],
    );
  }

  @override
  Future<int> deleteBoardGame(int bggId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'board_games',
      where: 'bgg_id = ?',
      whereArgs: [bggId],
    );
  }

// Is this method necessary with the delete cascade in place?
  @override
  Future<int> deleteBoardGameInTransaction(Transaction txn, int bggId) async {
    return await txn.delete(
      'board_games',
      where: 'bgg_id = ?',
      whereArgs: [bggId],
    );
  }


}