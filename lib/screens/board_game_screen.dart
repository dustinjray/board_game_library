import 'package:board_game_library/screens/edit_game_screen.dart';
import 'package:board_game_library/state/games_notifier.dart';
import 'package:board_game_library/widgets/game_item_expansion_tile.dart';
import 'package:board_game_library/widgets/game_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/board_game.dart';

class BoardGameScreen extends StatefulWidget {
	final BoardGame boardGame;

	const BoardGameScreen({
    super.key,
    required this.boardGame,
  });

	@override
	State<BoardGameScreen> createState() => _BoardGameScreenState();
}

class _BoardGameScreenState extends State<BoardGameScreen> {
	late BoardGame _currentGame;
	late bool _isFavorite;
	late bool _isOwned;
	late int _timesPlayed;
	bool _isSaving = false;
	bool _didUpdate = false;

	@override
	void initState() {
		super.initState();
		_currentGame = widget.boardGame;
		_isFavorite = widget.boardGame.isFavorite;
		_isOwned = widget.boardGame.isOwned;
		_timesPlayed = widget.boardGame.timesPlayed;
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
				timesPlayed: _timesPlayed,
			);

      await context.read<GamesNotifier>().updateGame(updatedGame);
			_didUpdate = true;

			if (mounted) {
				ScaffoldMessenger.of(context)
					..hideCurrentSnackBar()
					..showSnackBar(
						const SnackBar(content: Text('Game updated')),
					);
			}
		} catch (e) {
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('Failed to save changes: $e')),
				);
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
				),
				body: SingleChildScrollView(
					padding: const EdgeInsets.all(16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
						// Name and Year
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

						// Game Stats Card
            GameSummaryCard(game: game),
						const SizedBox(height: 16),

						// User Actions Card
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
															_isFavorite ? Icons.favorite : Icons.favorite_border,
															color: _isFavorite ? Colors.red : null,
														),
														label: Text(_isFavorite ? 'Favorite' : 'Not Favorite'),
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
															_isOwned ? Icons.check_circle : Icons.check_circle_outline,
															color: _isOwned ? Colors.green : null,
														),
														label: Text(_isOwned ? 'Owned' : 'Not Owned'),
													),
												),
											],
										),
										const SizedBox(height: 12),
										Row(
											mainAxisAlignment: MainAxisAlignment.spaceBetween,
											children: [
												Text(
													'Times Played',
													style: theme.textTheme.titleSmall,
												),
												Row(
													children: [
														IconButton(
															onPressed: (_timesPlayed > 0 && !_isSaving)
																	? () async {
																			setState(() {
																					_timesPlayed--;
																			});
																			await _persistChanges();
																		}
																		: null,
															icon: const Icon(Icons.remove_circle_outline),
														),
														SizedBox(
															width: 48,
															child: Text(
																'$_timesPlayed',
																textAlign: TextAlign.center,
																style: theme.textTheme.titleLarge,
															),
														),
														IconButton(
															onPressed: _isSaving
																	? null
																	: () async {
																			setState(() {
																					_timesPlayed++;
																			});
																			await _persistChanges();
																	},
															icon: const Icon(Icons.add_circle_outline),
														),
													],
												),
											],
										),
									],
								),
							),
						),
						const SizedBox(height: 16),

						// Categories
						if (game.categories.isNotEmpty)
              GameItemExpansionTile(
                title: 'Categories',
                items: game.categories,
                labelBuilder: (category) => category.name,
              ),

						// Mechanics
						if (game.mechanics.isNotEmpty)
              GameItemExpansionTile(
                title: 'Mechanics',
                items: game.mechanics,
                labelBuilder: (mechanic) => mechanic.name,
              ),

						// Expansions
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
			floatingActionButton: FloatingActionButton(
				child: const Icon(Icons.edit),
				onPressed: () async {
					final notifier = context.read<GamesNotifier>();
					final didUpdate = await Navigator.of(context).push<bool>(
						MaterialPageRoute(
							builder: (context) => EditGameScreen(boardGame: _currentGame),
						),
					);
					if (didUpdate == true && mounted) {
						final refreshed = await notifier.getGameById(_currentGame.bggId);
						if (refreshed != null && mounted) {
							setState(() {
								_currentGame = refreshed;
								_isFavorite = refreshed.isFavorite;
								_isOwned = refreshed.isOwned;
								_timesPlayed = refreshed.timesPlayed;
								_didUpdate = true;
							});
						}
					}
				},
			)
		));
	}
}
