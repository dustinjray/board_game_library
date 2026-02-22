import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';

abstract class GamesRepository {
  Future<int> countGames();
  Future<void> insertGamesBulk(
    List<BoardGame> games, {
    int chunkSize = 2000,
  });
  Future<List<BoardGame>> getAllGames();
  Future<BoardGame> getGameById(int id);
  Future<void> insertGame(BoardGame game);
  Future<void> insertGameWithRelations(BoardGame game);
  Future<void> updateGame(BoardGame game);
  Future<void> updateGameWithRelations(BoardGame game);
  Future<void> deleteGame(BoardGame game);
  Future<List<BoardGame>> searchByCriteria(BoardGameCriteria criteria);
  Future<List<BoardGameCategory>> filterOwnedCategories();
  Future<List<BoardGameMechanic>> filterOwnedMechanics();
  Future<List<BoardGameExpansion>> getExpansionsForGame(int bggId);
}
