import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:sqflite/sqflite.dart';

abstract class GamesDAO {
  Future<int> insertBoardGame(BoardGame game);
  Future<int> insertBoardGameInTransaction(Transaction txn, BoardGame game);
  Future<void> insertGamesBulk(List<BoardGame> games, {int chunkSize = 2000});
  Future<BoardGame?> getBoardGameById(int bggId);
  Future<List<BoardGame>> getAllGames();
  Future<List<BoardGame>> getAllBaseGames();
  Future<List<BoardGame>> getAllOwnedGames();
  Future<List<BoardGame>> getAllOwnedBaseGames();
  Future<List<BoardGame>> searchByCriteria(BoardGameCriteria criteria);
  Future<int> updateBoardGame(BoardGame game);
  Future<int> updateBoardGameInTransaction(Transaction txn, BoardGame game);
  Future<int> deleteBoardGame(int bggId);
  Future<int> deleteBoardGameInTransaction(Transaction txn, int bggId);
}