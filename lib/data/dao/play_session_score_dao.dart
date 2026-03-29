import 'package:board_game_library/models/play_session_score.dart';
import 'package:sqflite/sqflite.dart';

abstract class PlaySessionScoreDAO {
  Future<List<PlaySessionScore>> getScoresForSession(int playSessionId);
  Future<PlaySessionScore?> getScoreForSessionPlayer(
    int playSessionId,
    int playerId,
  );

  Future<int> insertSessionScore(PlaySessionScore score);
  Future<int> upsertSessionScore(PlaySessionScore score);
  Future<int> updateSessionScore(PlaySessionScore score);
  Future<int> deleteSessionScore(int playSessionId, int playerId);
  Future<int> deleteScoresForSession(int playSessionId);

  Future<int> insertSessionScoreInTransaction(
    Transaction txn,
    PlaySessionScore score,
  );
  Future<int> upsertSessionScoreInTransaction(
    Transaction txn,
    PlaySessionScore score,
  );
  Future<int> deleteScoresForSessionInTransaction(
    Transaction txn,
    int playSessionId,
  );
  Future<void> replaceScoresForSessionInTransaction(
    Transaction txn,
    int playSessionId,
    List<PlaySessionScore> scores,
  );
}
