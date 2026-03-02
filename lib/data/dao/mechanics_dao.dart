import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:sqflite/sqflite.dart';

abstract class MechanicsDAO {
	Future<int> insertMechanic(BoardGameMechanic mechanic);
	Future<void> persistMechanicsInTransaction(
		Transaction txn,
		int bggId,
		List<BoardGameMechanic> mechanics,
	);
	Future<int> updateMechanic(BoardGameMechanic mechanic);
	Future<void> deleteMechanic(int mechanicId);
  Future<BoardGameMechanic?> getMechanicById(int mechanicId);
	Future<List<BoardGameMechanic>> getMechanicsForGame(int bggId);
	Future<List<BoardGameMechanic>> getAllMechanics();
	Future<List<BoardGameMechanic>> getAllOwnedGameMechanics();
}