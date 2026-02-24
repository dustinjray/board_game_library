import 'package:board_game_library/data/repository/games_repository.dart';
import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/screens/board_game_screen.dart';
import 'package:board_game_library/services/board_game_service.dart';
import 'package:board_game_library/widgets/board_game_tile.dart';
import 'package:flutter/material.dart';

class AddToCollectionScreen extends StatefulWidget {
  final GamesRepository repository;
  final BoardGameService service;

  const AddToCollectionScreen({
    super.key,
    required this.repository,
    required this.service,
  });

  @override
  State<AddToCollectionScreen> createState() => _AddToCollectionScreenState();
}

class _AddToCollectionScreenState extends State<AddToCollectionScreen> {
  late final TextEditingController _searchController;
  late final Future<List<BoardGame>> _allGamesFuture;
  String _searchText = '';
  final Set<int> _updatingGameIds = <int>{};
  final Set<int> _newlyOwnedGameIds = <int>{};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _allGamesFuture = widget.repository.getAllGames();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addGameToCollection(BoardGame game) async {
    final isAlreadyOwned =
        game.isOwned || _newlyOwnedGameIds.contains(game.bggId);
    if (_updatingGameIds.contains(game.bggId) || isAlreadyOwned) {
      if (isAlreadyOwned) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${game.name} is already in your collection.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _updatingGameIds.add(game.bggId);
    });

    try {
      await widget.repository.updateGame(game.copyWith(isOwned: true));
      setState(() {
        _hasChanges = true;
        _newlyOwnedGameIds.add(game.bggId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${game.name} to your collection.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add ${game.name}: $error')),
      );
    } finally {
      setState(() {
        _updatingGameIds.remove(game.bggId);
      });
    }
  }

  Future<void> _openBoardGameScreen(BoardGame game) async {
    // Fetch details if not already present
    if (game.needsDetailsFetch) {
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

        final fetchedGame = await widget.service.fetchBoardGameDetails(game.bggId);
        
        // Merge fetched details with user-specific flags from local game
        final gameToSave = fetchedGame.copyWith(
          isFavorite: game.isFavorite,
          isOwned: game.isOwned,
          timesPlayed: game.timesPlayed,
        );

        // Update database with full details
        await widget.repository.updateGameWithRelations(gameToSave);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch game details: $e')),
          );
        }
        // Continue even if fetch fails - will load from database
      } finally {
        if (didShowLoading && mounted) {
          Navigator.of(context).pop();
        }
      }
    }

    if (!mounted) return;

    // Load game with relations from database
    final gameToShow = await widget.repository.getGameById(game.bggId);

    if (!mounted) return;

    final hasChanges = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            BoardGameScreen(
              boardGame: gameToShow,
              repository: widget.repository,
              service: widget.service,
            ),
      ),
    );

    if (!mounted) return;

    if (hasChanges == true) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Collection'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(_hasChanges),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BoardGame>>(
              future: _allGamesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Failed to load games: ${snapshot.error}'),
                    ),
                  );
                }

                final allGames = snapshot.data ?? const <BoardGame>[];
                final normalizedSearch = _searchText.trim().toLowerCase();
                final filteredGames = normalizedSearch.isEmpty
                    ? allGames
                    : allGames
                          .where(
                            (game) => game.name.toLowerCase().contains(
                              normalizedSearch,
                            ),
                          )
                          .toList();

                if (filteredGames.isEmpty) {
                  return const Center(child: Text('No games found.'));
                }

                return ListView.builder(
                  itemCount: filteredGames.length,
                  itemBuilder: (context, index) {
                    final game = filteredGames[index];
                    final isUpdating = _updatingGameIds.contains(game.bggId);
                    final isOwned =
                        game.isOwned || _newlyOwnedGameIds.contains(game.bggId);
                    return BoardGameTile(
                      boardGame: game,
                      onTap: () => _openBoardGameScreen(game),
                      trailing: isUpdating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              onPressed: isOwned
                                  ? null
                                  : () => _addGameToCollection(game),
                              icon: Icon(isOwned ? Icons.check : Icons.add),
                              tooltip: isOwned
                                  ? 'Already in collection'
                                  : 'Add to collection',
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
