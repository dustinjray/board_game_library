import 'package:board_game_library/models/play_session.dart';
import 'package:board_game_library/models/play_session_score.dart';

class PlaySessionDetails {
  final PlaySession session;
  final List<PlaySessionScore> scores;
  final List<int> expansionIds;

  PlaySessionDetails({
    required this.session,
    required this.scores,
    this.expansionIds = const [],
  });

  PlaySessionDetails copyWith({
    PlaySession? session,
    List<PlaySessionScore>? scores,
    List<int>? expansionIds,
  }) {
    return PlaySessionDetails(
      session: session ?? this.session,
      scores: scores ?? this.scores,
      expansionIds: expansionIds ?? this.expansionIds,
    );
  }

  PlaySession get playSession => session;
  List<PlaySessionScore> get playSessionScores => scores;
  List<int> get selectedExpansionIds => expansionIds;
}
