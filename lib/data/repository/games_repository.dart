import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';

abstract class GamesRepository {
  Future<int> countGames();
  Future<void> insertGamesBulk(List<BoardGame> games, {int chunkSize = 2000});

  /// Returns all games without loading categories/mechanics/expansions.
  Future<List<BoardGame>> getAllGames();
  Future<List<BoardGame>> getAllBaseGames();

  /// Returns a single game and includes related categories/mechanics/expansions.
  Future<BoardGame?> getGameById(int id);
  Future<void> insertGame(BoardGame game);
  Future<void> persistGameWithRelations(BoardGame game, bool isUpdate);
  Future<void> addGameToCollection(BoardGame game);
  Future<void> updateIsFavorite(BoardGame game, bool isFavorite);
  Future<void> updateIsOwned(BoardGame game, bool isOwned);
  Future<void> insertGameWithRelations(BoardGame game);
  Future<void> updateGame(BoardGame game);
  Future<void> updateGameWithRelations(BoardGame game);
  Future<void> deleteGame(BoardGame game);
  Future<List<BoardGame>> getAllOwnedGames();
  Future<List<BoardGame>> getAllOwnedBaseGames();
  Future<List<BoardGame>> searchByCriteria(BoardGameCriteria criteria);
  Future<List<BoardGameCategory>> filterOwnedCategories();
  Future<List<BoardGameMechanic>> filterOwnedMechanics();
  Future<List<BoardGameExpansion>> getExpansionsForGame(int bggId);
  Future<List<BoardGame>> getAllGamesPaged(
    int page,
    int pageSize, {
    String? namePrefix,
  });
  Future<List<BoardGame>> getOwnedGamesPaged(
    int page,
    int pageSize, {
    String? namePrefix,
    BoardGameCriteria? criteria,
  });
}
