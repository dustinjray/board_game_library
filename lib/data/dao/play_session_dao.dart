import 'package:board_game_library/models/play_session.dart';
import 'package:sqflite/sqflite.dart';

abstract class PlaySessionDAO {
  Future<List<PlaySession>> getAllPlaySessions();
  Future<List<PlaySession>> getPlaySessionsForGame(int bggId);
  Future<int> countSessionsForGame(int bggId);
  Future<PlaySession?> getPlaySessionById(int sessionId);

  Future<int> insertPlaySession(PlaySession session);
  Future<int> updatePlaySession(PlaySession session);
  Future<void> deletePlaySession(int sessionId);

  Future<int> insertPlaySessionInTransaction(
    Transaction txn,
    PlaySession session,
  );
  Future<int> updatePlaySessionInTransaction(
    Transaction txn,
    PlaySession session,
  );
  Future<void> deletePlaySessionInTransaction(Transaction txn, int sessionId);

  Future<T> runInTransaction<T>(Future<T> Function(Transaction txn) action);
}
