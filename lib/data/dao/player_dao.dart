import 'package:board_game_library/models/player.dart';
import 'package:sqflite/sqflite.dart';

abstract class PlayerDAO {
  Future<List<Player>> getAllPlayers();
  Future<Player> getPlayerById(int playerId);
  Future<List<Player>> getPlayersForSession(int sessionId);

  Future<int> addPlayer(Player player);
  Future<int> addPlayerInTransaction(Transaction txn, Player player);
  Future<int> updatePlayer(Player player);
  Future<void> deletePlayer(int playerId);

  Future<Player?> findPlayerByNormalizedName(String normalizedName);
  Future<Player?> findPlayerByNormalizedNameInTransaction(
    Transaction txn,
    String normalizedName,
  );
}
