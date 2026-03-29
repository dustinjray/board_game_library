import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/play_session_details.dart';
import 'package:board_game_library/models/play_session_score.dart';
import 'package:board_game_library/screens/add_play_session_screen.dart';
import 'package:board_game_library/state/play_session_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaySessionSection extends StatefulWidget {
  final BoardGame game;

  const PlaySessionSection({super.key, required this.game});

  @override
  State<PlaySessionSection> createState() => _PlaySessionSectionState();
}

class _PlaySessionSectionState extends State<PlaySessionSection> {
  final Set<int> _expandedSessionIds = <int>{};
  List<PlaySessionDetails>? _lastSessionsRef;

  String _formatDateTime(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $displayHour:$minute $ampm';
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    PlaySessionDetails details,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Delete this play session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<PlaySessionNotifier>().deleteSession(
      details.session,
      widget.game.bggId,
    );
  }

  InlineSpan _winnerAwarePlayerName(
    BuildContext context,
    String name,
    bool isWinner,
    double iconSize,
  ) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    if (!isWinner) {
      return TextSpan(text: name, style: baseStyle);
    }

    return TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: iconSize,
            ),
          ),
        ),
        TextSpan(
          text: name,
          style: baseStyle?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  InlineSpan _playerSummarySpan(
    BuildContext context,
    List<PlaySessionScore> scores,
  ) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < scores.length; i++) {
      final score = scores[i];
      final name = score.player?.name ?? 'Unknown player';
      spans.add(_winnerAwarePlayerName(context, name, score.isWinner, 14));
      if (i < scores.length - 1) {
        spans.add(
          TextSpan(
            text: ', ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.select<PlaySessionNotifier, bool>(
      (notifier) => notifier.isLoading,
    );
    final sessions = context.select<PlaySessionNotifier, List<PlaySessionDetails>>(
      (notifier) => notifier.sessions,
    );

    // After edits/saves, notifier assigns a new sessions list. Clearing cached
    // expansion ids avoids stale "collapsed but subtitle hidden" mismatches.
    if (!identical(_lastSessionsRef, sessions)) {
      _expandedSessionIds.clear();
      _lastSessionsRef = sessions;
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ExpansionTile(
      title: Text(
        'Times Played: ${sessions.length}',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Play Session'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AddPlaySessionScreen(boardGame: widget.game),
                ),
              ),
            ),
          ),
        ),
        if (sessions.isEmpty)
          const ListTile(
            dense: true,
            title: Text('No sessions recorded yet.'),
          ),
        ...sessions
            .map((details) {
              final isExpanded = _expandedSessionIds.contains(details.session.id);

              return ExpansionTile(
                title: Text(
                  _formatDateTime(details.session.datePlayed),
                ),
                subtitle: !isExpanded && details.scores.isNotEmpty
                    ? Text.rich(
                        _playerSummarySpan(context, details.scores),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                onExpansionChanged: (expanded) {
                  setState(() {
                    if (expanded) {
                      _expandedSessionIds.add(details.session.id);
                    } else {
                      _expandedSessionIds.remove(details.session.id);
                    }
                  });
                },
                children: [
                  ...ListTile.divideTiles(
                    context: context,
                    tiles: details.scores.map((score) {
                      final name = score.player?.name ?? 'Unknown player';
                      return ListTile(
                        dense: true,
                        title: Text.rich(
                          _winnerAwarePlayerName(
                            context,
                            name,
                            score.isWinner,
                            16,
                          ),
                        ),
                        trailing: Text(score.scoreSummaryLabel ?? 'N/A'),
                      );
                    }),
                    color: theme.dividerColor.withValues(alpha: 0.6),
                  ).toList(growable: false),
                  ListTile(
                    dense: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit session'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddPlaySessionScreen(
                                boardGame: widget.game,
                                existingDetails: details,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete session'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => _confirmDeleteSession(context, details),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            })
            .toList(growable: false),
      ],
    );
  }
}
