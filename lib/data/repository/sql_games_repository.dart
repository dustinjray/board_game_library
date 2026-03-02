import 'package:board_game_library/data/dao/categories_dao.dart';
import 'package:board_game_library/data/dao/expansions_dao.dart';
import 'package:board_game_library/data/dao/games_dao.dart';
import 'package:board_game_library/data/dao/mechanics_dao.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/data/repository/games_repository.dart';
import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';

class SqlGamesRepository implements GamesRepository {
  final DatabaseHelper _dbHelper;
  final GamesDAO _gamesDAO;
  final CategoriesDAO _categoriesDAO;
  final MechanicsDAO _mechanicsDAO;
  final ExpansionsDAO _expansionsDAO;

  SqlGamesRepository(this._dbHelper, this._gamesDAO, this._categoriesDAO, this._mechanicsDAO, this._expansionsDAO);

  @override
  Future<int> countGames() async {
    final allGames = await _gamesDAO.getAllGames();
    return allGames.length;
  }

  @override
  Future<void> insertGamesBulk(
    List<BoardGame> games, {
    int chunkSize = 2000,
  }) async {
    await _gamesDAO.insertGamesBulk(games, chunkSize: chunkSize);
  }

  @override
  Future<void> insertGame(BoardGame game) async {
    final result = await _gamesDAO.insertBoardGame(game);
    if (result == 0) {
      print('Skipped insert for existing game with id ${game.bggId}');
      return;
    }
    print('Inserted game with id ${game.bggId}');
  }

  @override
  Future<void> persistGameWithRelations(BoardGame game, bool isUpdate) {
    if (isUpdate) {
      return updateGameWithRelations(game);
    } else {
      return insertGameWithRelations(game);
    }
  }

  @override
  Future<void> insertGameWithRelations(BoardGame game) async {
    // This would be when inserting a game from the BGG API that did not exist in the database before.
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final gameId = await _gamesDAO.insertBoardGameInTransaction(txn, game);
      if (gameId == 0) {
        throw Exception('Failed to insert game with id ${game.bggId}');
      }
      await _categoriesDAO.persistCategoriesInTransaction(txn, game.bggId, game.categories);
      await _mechanicsDAO.persistMechanicsInTransaction(txn, game.bggId, game.mechanics);
      await _expansionsDAO.persistExpansionsInTransaction(txn, game.bggId, game.expansions);
    });
  }

  @override
  Future<void> deleteGame(BoardGame game) async {
    var result = await _gamesDAO.deleteBoardGame(game.bggId);
    if (result == 0) {
      throw Exception('Failed to delete game with id ${game.bggId}');
    } else {
      print('Deleted game with id ${game.bggId}');
    }
  }

  @override
  Future<List<BoardGame>> getAllGames() async {
    // Intentionally returns base board game rows only (no relations).
    return await _gamesDAO.getAllGames();
  }

  @override
  Future<List<BoardGame>> getAllBaseGames() async {
    // Intentionally returns base board game rows only (no relations), and filters out expansions.
    return await _gamesDAO.getAllBaseGames();
  }

  @override
  Future<BoardGame?> getGameById(int id) async {
    // Loads the game with all its relations (categories/mechanics/expansions).
    final game = await _gamesDAO.getBoardGameById(id);
    if (game == null) {
      return null;
    }
    final categories = await _categoriesDAO.getCategoriesForGame(id);
    final mechanics = await _mechanicsDAO.getMechanicsForGame(id);
    final expansions = await _expansionsDAO.getExpansionsForGame(id);
    // game.categories.addAll(await _categoriesDAO.getCategoriesForGame(id));
    // game.mechanics.addAll(await _mechanicsDAO.getMechanicsForGame(id));
    // game.expansions.addAll(await _expansionsDAO.getExpansionsForGame(id));

    return game.copyWith(categories:categories, mechanics:mechanics, expansions:expansions);
  }

  @override
  Future<List<BoardGame>> getAllOwnedGames() async {
    // Loads all owned games, but without categories/mechanics/expansions.
    return await _gamesDAO.getAllOwnedGames();
  }

  @override
  Future<List<BoardGame>> getAllOwnedBaseGames() async {
    // Loads all owned base games, but without categories/mechanics/expansions.
    return await _gamesDAO.getAllOwnedBaseGames();
  }


  @override
  Future<List<BoardGame>> searchByCriteria(BoardGameCriteria criteria) async {
    return await _gamesDAO.searchByCriteria(criteria);
  }

  @override
  Future<void> updateGame(BoardGame game) async {
    // Updates only the base game row, without touching categories/mechanics/expansions.
    final result = await _gamesDAO.updateBoardGame(game);
    if (result == 0) {
      throw Exception('Failed to update game with id ${game.bggId}');
    } else {
      print('Updated game with id ${game.bggId}');
    }
  }

  @override
  Future<void> updateGameWithRelations(BoardGame game) async {
    // Updates the base game row, and also updates all mechanics/categories/expansions by deleting existing ones and re-inserting current ones.
    // Primarily used to add game details to an existing row with extra data from the BGG API.
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final result = await _gamesDAO.updateBoardGameInTransaction(txn, game);
      if (result == 0) {
        throw Exception('Failed to update game with id ${game.bggId}');
      }
      await _categoriesDAO.persistCategoriesInTransaction(txn, game.bggId, game.categories);
      await _mechanicsDAO.persistMechanicsInTransaction(txn, game.bggId, game.mechanics);
      await _expansionsDAO.persistExpansionsInTransaction(txn, game.bggId, game.expansions);
    });
  }

  @override
  Future<List<BoardGameCategory>> filterOwnedCategories() async {
    // Loads all categories that are associated with at least one owned game. This is used to populate the category filter chips in the UI.
    return await _categoriesDAO.getAllOwnedGameCategories();
  }

  @override
  Future<List<BoardGameMechanic>> filterOwnedMechanics() async {
    // Loads all mechanics that are associated with at least one owned game. This is used to populate the mechanic filter chips in the UI.
    return await _mechanicsDAO.getAllOwnedGameMechanics();
  }

  @override
  Future<List<BoardGameExpansion>> getExpansionsForGame(int bggId) async {
    // Loads all expansions for a specific game. This is used to display the expansions in the UI.
    return await _expansionsDAO.getExpansionsForGame(bggId);
  }

}