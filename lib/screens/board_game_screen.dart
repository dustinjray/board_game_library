import 'package:board_game_library/screens/edit_game_screen.dart';
import 'package:board_game_library/state/games_notifier.dart';
import 'package:board_game_library/state/play_session_notifier.dart';
import 'package:board_game_library/widgets/bgg_link_button.dart';
import 'package:board_game_library/widgets/game_item_expansion_tile.dart';
import 'package:board_game_library/widgets/game_summary_card.dart';
import 'package:board_game_library/widgets/play_session_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/board_game.dart';

enum BoardGameScreenMode {
  fullAccess,
  addToCollectionPreview,
}

class BoardGameScreen extends StatefulWidget {
  final BoardGame boardGame;
  final BoardGameScreenMode mode;

  const BoardGameScreen({
    super.key,
    required this.boardGame,
    this.mode = BoardGameScreenMode.fullAccess,
  });

  @override
  State<BoardGameScreen> createState() => _BoardGameScreenState();
}

class _BoardGameScreenState extends State<BoardGameScreen> {
  late BoardGame _currentGame;
  late bool _isFavorite;
  late bool _isOwned;
  bool _isSaving = false;
  bool _didUpdate = false;

  @override
  void initState() {
    super.initState();
    _currentGame = widget.boardGame;
    _isFavorite = widget.boardGame.isFavorite;
    _isOwned = widget.boardGame.isOwned;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PlaySessionNotifier>().loadSessionsForGame(
        _currentGame.bggId,
      );
    });
  }

  Future<void> _persistChanges() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedGame = _currentGame.copyWith(
        isFavorite: _isFavorite,
        isOwned: _isOwned,
      );

      await context.read<GamesNotifier>().updateGame(updatedGame);

      _didUpdate = true;

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Game updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _currentGame;
    final theme = Theme.of(context);

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_didUpdate);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${game.name}${game.isExpansion ? ' - EXPANSION' : ''}'),
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_didUpdate),
          ),
          actions: const [
            BggLinkButton(),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (game.yearPublished != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Published ${game.yearPublished}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              GameSummaryCard(game: game),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Collection',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isFavorite = !_isFavorite;
                                      });
                                      await _persistChanges();
                                    },
                              icon: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : null,
                              ),
                              label: Text(
                                _isFavorite ? 'Favorite' : 'Not Favorite',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isOwned = !_isOwned;
                                      });
                                      await _persistChanges();
                                    },
                              icon: Icon(
                                _isOwned
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: _isOwned ? Colors.green : null,
                              ),
                              label: Text(_isOwned ? 'Owned' : 'Not Owned'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PlaySessionSection(game: game),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (game.categories.isNotEmpty)
                GameItemExpansionTile(
                  title: 'Categories',
                  items: game.categories,
                  labelBuilder: (category) => category.name,
                ),
              if (game.mechanics.isNotEmpty)
                GameItemExpansionTile(
                  title: 'Mechanics',
                  items: game.mechanics,
                  labelBuilder: (mechanic) => mechanic.name,
                ),
              if (game.expansions.isNotEmpty)
                GameItemExpansionTile(
                  title: 'Expansions',
                  items: game.expansions,
                  labelBuilder: (expansion) => expansion.name,
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        floatingActionButton: widget.mode == BoardGameScreenMode.fullAccess
            ? FloatingActionButton(
                child: const Icon(Icons.edit),
                onPressed: () async {
                  final notifier = context.read<GamesNotifier>();
                  final playSessionNotifier = context.read<PlaySessionNotifier>();
                  final didUpdate = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) =>
                          EditGameScreen(boardGame: _currentGame),
                    ),
                  );
                  if (didUpdate == true && mounted) {
                    final refreshed = await notifier.getGameById(
                      _currentGame.bggId,
                    );
                    if (refreshed != null && mounted) {
                      setState(() {
                        _currentGame = refreshed;
                        _isFavorite = refreshed.isFavorite;
                        _isOwned = refreshed.isOwned;
                        _didUpdate = true;
                      });
                      await playSessionNotifier.loadSessionsForGame(
                        _currentGame.bggId,
                      );
                    }
                  }
                },
              )
            : null,
      ),
    );
  }
}
