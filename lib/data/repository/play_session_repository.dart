import 'package:board_game_library/models/play_session.dart';
import 'package:board_game_library/models/play_session_details.dart';
import 'package:board_game_library/models/play_session_score.dart';
import 'package:board_game_library/models/player.dart';

abstract class PlaySessionRepository {
  Future<void> insertPlaySession(PlaySession playSession);
  Future<void> updatePlaySession(PlaySession playSession);
  Future<void> deletePlaySession(PlaySession playSession);
  Future<List<PlaySession>> getAllPlaySessions();
  Future<List<PlaySession>> getPlaySessionsForGame(int bggId);
  Future<int> countSessionsForGame(int bggId);
  Future<int> countSessionsForExpansion(int expansionId);
  Future<PlaySession?> getPlaySessionById(int sessionId);
  Future<void> insertPlaySessionScore(PlaySessionScore score);
  Future<List<PlaySessionScore>> getScoresForSession(int playSessionId);
  Future<List<int>> getExpansionIdsForSession(int playSessionId);
  Future<PlaySessionScore?> getScoreForSessionPlayer(
    int playSessionId,
    int playerId,
  );
  Future<List<Player>> getPlayersForSession(int sessionId);
  Future<List<Player>> getAllPlayers();
  Future<PlaySessionDetails> persistSessionDetails(PlaySessionDetails details);
}
