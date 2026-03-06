import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/widgets/info_row_widget.dart';
import 'package:flutter/material.dart';

class GameSummaryCard extends StatelessWidget {
  final BoardGame game;
  const GameSummaryCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )
            ),
            const SizedBox(height: 12),
            if (game.minPlayers != null && game.maxPlayers != null)
              InfoRowWidget(
                label: 'Players',
                value: '${game.minPlayers} - ${game.maxPlayers}',
              ),
            if (game.minPlaytime != null && game.maxPlaytime != null)
              InfoRowWidget(
                label: 'Playtime',
                value: '${game.minPlaytime} - ${game.maxPlaytime} mins',
              ),
            if (game.age != null)
              InfoRowWidget(
                label: 'Age',
                value: '${game.age}+',
              ),
          ]
        )
      )
    );
  }
}