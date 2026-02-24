import 'package:board_game_library/models/board_game.dart';
import 'package:flutter/material.dart';

class BoardGameTile extends ListTile {
  BoardGameTile({
    super.key,
    required BoardGame boardGame,
    ShapeBorder? shape,
    super.onTap,
    super.trailing,
  }) : super(
         title: Text(boardGame.name),
         subtitle: _buildSubtitle(boardGame),
         shape:
             shape ??
             const RoundedRectangleBorder(side: BorderSide(width: 0.5)),
       );

  static Widget? _buildSubtitle(BoardGame boardGame) {
    final players = _playersLabel(boardGame);
    final playtime = _playtimeLabel(boardGame);

    if (players == null && playtime == null) {
      return null;
    }

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (players != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_alt, size: 16),
              const SizedBox(width: 4),
              Text(players),
            ],
          ),
        if (playtime != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_alarm, size: 16),
              const SizedBox(width: 4),
              Text(playtime),
            ],
          ),
      ],
    );
  }

  static String? _playersLabel(BoardGame boardGame) {
    final minPlayers = boardGame.minPlayers;
    final maxPlayers = boardGame.maxPlayers;
    if (minPlayers == null && maxPlayers == null) {
      return null;
    }
    if (minPlayers != null && maxPlayers != null) {
      return '$minPlayers-$maxPlayers';
    }
    return (minPlayers ?? maxPlayers).toString();
  }

  static String? _playtimeLabel(BoardGame boardGame) {
    final minPlaytime = boardGame.minPlaytime;
    final maxPlaytime = boardGame.maxPlaytime;
    if (minPlaytime == null && maxPlaytime == null) {
      return null;
    }
    if (minPlaytime != null && maxPlaytime != null) {
      return '$minPlaytime-$maxPlaytime min';
    }
    return '${minPlaytime ?? maxPlaytime} min';
  }
}
