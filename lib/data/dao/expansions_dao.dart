import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:sqflite/sqflite.dart';

abstract class ExpansionsDAO {
	Future<int> insertExpansion(BoardGameExpansion expansion);
	Future<void> persistExpansionsInTransaction(
		Transaction txn,
		int bggId,
		List<BoardGameExpansion> expansions,
	);
	Future<int> updateExpansion(BoardGameExpansion expansion);
	Future<void> deleteExpansion(int expansionId);
  Future<BoardGameExpansion?> getExpansionById(int expansionId);
	Future<List<BoardGameExpansion>> getExpansionsForGame(int bggId);
	Future<List<BoardGameExpansion>> getAllExpansions();
	Future<List<BoardGameExpansion>> getAllOwnedGameExpansions();
}