import 'package:board_game_library/data/repository/games_repository.dart';
import 'package:board_game_library/services/board_game_service.dart';
import 'package:flutter/material.dart';

import '../models/board_game.dart';

class BoardGameScreen extends StatefulWidget {
	final BoardGame boardGame;
  final GamesRepository repository;
  final BoardGameService service;

	const BoardGameScreen({
    super.key,
    required this.boardGame,
    required this.repository,
    required this.service,
  });

	@override
	State<BoardGameScreen> createState() => _BoardGameScreenState();
}

class _BoardGameScreenState extends State<BoardGameScreen> {
	late bool _isFavorite;
	late bool _isOwned;
	late int _timesPlayed;
	bool _isSaving = false;
	bool _didUpdate = false;

	@override
	void initState() {
		super.initState();
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
			final updatedGame = widget.boardGame.copyWith(
				isFavorite: _isFavorite,
				isOwned: _isOwned,
				timesPlayed: _timesPlayed,
			);

			await widget.repository.updateGame(updatedGame);

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

	Future<void> _openExpansionScreen(int expansionId) async {
		late BoardGame expansion;

		try {
			// Try to get from database first
			expansion = await widget.repository.getGameById(expansionId) ?? (throw Exception('Game not found in database'));
		} catch (e) {
			// Not in database, try fetching from service
			var didShowLoading = false;
			try {
				if (mounted) {
					didShowLoading = true;
					showDialog<void>(
						context: context,
						barrierDismissible: false,
						builder: (context) => const Center(
							child: CircularProgressIndicator(),
						),
					);
				}

				final fetchedGame = await widget.service.fetchBoardGameDetails(expansionId);
				
				// Save to database for future use
				await widget.repository.insertGameWithRelations(fetchedGame);
				expansion = fetchedGame;
			} catch (serviceError) {
				if (mounted) {
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(content: Text('Failed to load expansion: $serviceError')),
					);
				}
				return;
			} finally {
				if (didShowLoading && mounted) {
					Navigator.of(context).pop();
				}
			}
		}

		if (!mounted) return;

		final hasChanges = await Navigator.of(context).push<bool>(
			MaterialPageRoute(
				builder: (context) => BoardGameScreen(
					boardGame: expansion,
					repository: widget.repository,
					service: widget.service,
				),
			),
		);

		// Propagate changes up the navigation stack
		if (hasChanges == true && mounted) {
			Navigator.of(context).pop(true);
		}
	}

	@override
	Widget build(BuildContext context) {
		final game = widget.boardGame;
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
						Card(
							child: Padding(
								padding: const EdgeInsets.all(16),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											'Game Information',
											style: theme.textTheme.titleMedium?.copyWith(
												fontWeight: FontWeight.bold,
											),
										),
										const SizedBox(height: 12),
										if (game.minPlayers != null || game.maxPlayers != null)
											_buildInfoRow(
												'Players',
												game.minPlayers != null && game.maxPlayers != null
														? '${game.minPlayers} - ${game.maxPlayers}'
														: game.minPlayers?.toString() ?? game.maxPlayers.toString(),
											),
										if (game.minPlaytime != null || game.maxPlaytime != null)
											_buildInfoRow(
												'Playtime',
												game.minPlaytime != null && game.maxPlaytime != null
														? '${game.minPlaytime} - ${game.maxPlaytime} min'
														: game.minPlaytime != null
																? '${game.minPlaytime} min'
																: '${game.maxPlaytime} min',
											),
										if (game.age != null)
											_buildInfoRow('Age', '${game.age}+'),
									],
								),
							),
						),
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
							ExpansionTile(
								title: Text(
									'Categories (${game.categories.length})',
									style: theme.textTheme.titleMedium?.copyWith(
										fontWeight: FontWeight.bold,
									),
								),
								children: game.categories
										.map((category) => ListTile(
													dense: true,
													title: Text(category.name),
												))
										.toList(),
							),

						// Mechanics
						if (game.mechanics.isNotEmpty)
							ExpansionTile(
								title: Text(
									'Mechanics (${game.mechanics.length})',
									style: theme.textTheme.titleMedium?.copyWith(
										fontWeight: FontWeight.bold,
									),
								),
								children: game.mechanics
										.map((mechanic) => ListTile(
													dense: true,
													title: Text(mechanic.name),
												))
										.toList(),
							),

						// Expansions
						if (game.expansions.isNotEmpty)
							ExpansionTile(
								title: Text(
									'Expansions (${game.expansions.length})',
									style: theme.textTheme.titleMedium?.copyWith(
										fontWeight: FontWeight.bold,
									),
								),
								children: game.expansions
										.map((expansion) => ListTile(
													dense: true,
													title: Text(expansion.name),
													trailing: const Icon(Icons.arrow_forward_ios, size: 16),
													onTap: () => _openExpansionScreen(expansion.id),
												))
										.toList(),
							),

						const SizedBox(height: 16),
					],
				),
			),
		));
	}

	Widget _buildInfoRow(String label, String value) {
		return Padding(
			padding: const EdgeInsets.only(bottom: 8),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					Text(
						label,
						style: Theme.of(context).textTheme.bodyMedium,
					),
					Text(
						value,
						style: Theme.of(context).textTheme.bodyMedium?.copyWith(
									fontWeight: FontWeight.bold,
								),
					),
				],
			),
		);
	}
}
