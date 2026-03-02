import 'package:board_game_library/models/board_game_category.dart';
import 'package:sqflite/sqflite.dart';

abstract class CategoriesDAO {
	Future<int> insertCategory(BoardGameCategory category);
	Future<void> persistCategoriesInTransaction(
		Transaction txn,
		int bggId,
		List<BoardGameCategory> categories,
	);
	Future<int> updateCategory(BoardGameCategory category);
	Future<void> deleteCategory(int categoryId);
  Future<BoardGameCategory?> getCategoryById(int categoryId);
	Future<List<BoardGameCategory>> getCategoriesForGame(int bggId);
	Future<List<BoardGameCategory>> getAllCategories();
	Future<List<BoardGameCategory>> getAllOwnedGameCategories();
}