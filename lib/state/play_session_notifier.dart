import 'package:board_game_library/data/repository/play_session_repository.dart';
import 'package:board_game_library/models/play_session.dart';
import 'package:board_game_library/models/play_session_details.dart';
import 'package:board_game_library/models/player.dart';
import 'package:flutter/foundation.dart';

class PlaySessionNotifier extends ChangeNotifier {
  final PlaySessionRepository _repository;

  bool isLoading = false;
  bool isPlayersLoading = false;
  List<PlaySessionDetails> sessions = [];
  List<Player> players = [];

  PlaySessionNotifier(this._repository);

  Future<void> loadSessionsForGame(int bggId) async {
    isLoading = true;
    notifyListeners();
    final details = <PlaySessionDetails>[];
    try {
      final playSessions = await _repository.getPlaySessionsForGame(bggId);
      for (final session in playSessions) {
        final scores = await _repository.getScoresForSession(session.id);
        final players = await _repository.getPlayersForSession(session.id);
        final expansionIds = await _repository.getExpansionIdsForSession(
          session.id,
        );

        final playerMap = {for (var player in players) player.id!: player};

        final scoresWithPlayers = scores
            .map((score) => score.copyWith(player: playerMap[score.playerId]))
            .toList(growable: false);
        details.add(
          PlaySessionDetails(
            session: session,
            scores: scoresWithPlayers,
            expansionIds: expansionIds,
          ),
        );
      }
      sessions = details;
    } catch (e) {
      // Handle error, e.g. log it
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllPlayers() async {
    isPlayersLoading = true;
    notifyListeners();

    try {
      players = await _repository.getAllPlayers();
    } catch (e) {
      // Handle error, e.g. log it
    } finally {
      isPlayersLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveSession(PlaySessionDetails details, int bggId) async {
    await _repository.persistSessionDetails(details);
    await loadSessionsForGame(bggId);
  }

  Future<void> deleteSession(PlaySession session, int bggId) async {
    await _repository.deletePlaySession(session);
    await loadSessionsForGame(bggId);
  }
}
