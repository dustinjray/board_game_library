import 'package:board_game_library/models/play_session_score.dart';
import 'package:flutter/material.dart';

class ScoreRowWidget extends StatelessWidget {
  final PlaySessionScore score;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const ScoreRowWidget({
    super.key,
    required this.score,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = score.player?.name ?? 'Unknown player';
    final scoreLabel = score.scoreSummaryLabel ?? 'N/A';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text(scoreLabel),
      leading: score.isWinner
          ? const Icon(Icons.emoji_events, color: Colors.amber)
          : const Icon(Icons.person_outline),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Edit score',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Remove score',
            icon: Icon(
              Icons.remove_circle_outline,
              color: theme.colorScheme.error,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
      onTap: onEdit,
    );
  }
}
