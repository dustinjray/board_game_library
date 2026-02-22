import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/data/repository/games_repository.dart';
import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';

class SqlGamesRepository implements GamesRepository {
  final DatabaseHelper _dbHelper;

  SqlGamesRepository(this._dbHelper);

  @override
  Future<int> countGames() async {
    return _dbHelper.getBoardGameCount();
  }

  @override
  Future<void> insertGamesBulk(
    List<BoardGame> games, {
    int chunkSize = 2000,
  }) async {
    await _dbHelper.insertBoardGamesBulk(games, chunkSize: chunkSize);
  }

  @override
  Future<void> insertGame(BoardGame game) async {
    final result = await _dbHelper.insertBoardGame(game);
    if (result == 0) {
      print('Skipped insert for existing game with id ${game.bggId}');
      return;
    }
    print('Inserted game with id ${game.bggId}');
  }

  @override
  Future<void> insertGameWithRelations(BoardGame game) async {
    await _dbHelper.insertBoardGameWithRelations(game);
    print('Inserted game with relations for id ${game.bggId}');
  }

  @override
  Future<void> deleteGame(BoardGame game) async {
    var result = await _dbHelper.deleteBoardGame(game.bggId);
    if (result == 0) {
      throw Exception('Failed to delete game with id ${game.bggId}');
    } else {
      print('Deleted game with id ${game.bggId}');
    }
  }

  @override
  Future<List<BoardGame>> getAllGames() async {
    return await _dbHelper.getAllBoardGames();
  }

  @override
  Future<BoardGame> getGameById(int id) async {
    var game = await _dbHelper.getBoardGameById(id);
    if (game != null) {
      return game;
    } else {
      throw Exception('Game with id $id not found');
    }
  }

  @override
  Future<List<BoardGame>> searchByCriteria(BoardGameCriteria criteria) async {
    var result = await _dbHelper.searchByCriteria(criteria);
    return result;
  }

  @override
  Future<void> updateGame(BoardGame game) async {
    final result = await _dbHelper.updateBoardGame(game);
    if (result == 0) {
      final existingGame = await _dbHelper.getBoardGameById(game.bggId);
      if (existingGame == null) {
        throw Exception('Game with id ${game.bggId} not found');
      }
      print('No changes for game with id ${game.bggId}');
      return;
    }
    print('Updated game with id ${game.bggId}');
  }

  @override
  Future<void> updateGameWithRelations(BoardGame game) async {
    final existingGame = await _dbHelper.getBoardGameById(game.bggId);
    if (existingGame == null) {
      throw Exception('Game with id ${game.bggId} not found');
    }
    await _dbHelper.updateBoardGameWithRelations(game);
    print('Updated game with relations for id ${game.bggId}');
  }

  @override
  Future<List<BoardGameCategory>> filterOwnedCategories() async {
    return await _dbHelper.getOwnedCategories();
  }

  @override
  Future<List<BoardGameMechanic>> filterOwnedMechanics() async {
    return await _dbHelper.getOwnedMechanics();
  }

  @override
  Future<List<BoardGameExpansion>> getExpansionsForGame(int bggId) async {
    return await _dbHelper.getExpansionsForGame(bggId);
  }

}