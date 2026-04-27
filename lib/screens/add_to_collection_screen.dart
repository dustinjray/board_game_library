import 'dart:async';

import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/data/repository/sql_games_repository.dart';
import 'package:board_game_library/screens/board_game_screen.dart';
import 'package:board_game_library/services/board_game_service.dart';
import 'package:board_game_library/state/games_notifier.dart';
import 'package:board_game_library/widgets/bgg_link_button.dart';
import 'package:board_game_library/widgets/board_game_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddToCollectionScreen extends StatefulWidget {

  const AddToCollectionScreen({
    super.key,
  });

  @override
  State<AddToCollectionScreen> createState() => _AddToCollectionScreenState();
}

class _AddToCollectionScreenState extends State<AddToCollectionScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  Timer? _searchDebounce;

  List<BoardGame> _visibleGames = <BoardGame>[];
  String _searchText = '';
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  int _queryVersion = 0;
  bool _loadQueued = false;
  final Set<int> _updatingGameIds = <int>{};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        setState(() {
          _searchText = _searchController.text;
          _currentPage = 0;
          _visibleGames = <BoardGame>[];
          _hasMore = true;
          _queryVersion++;
        });

        if (_isLoading) {
          _loadQueued = true;
        } else {
          _loadMoreGames();
        }
      });
    });

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        _loadMoreGames();
      }
    });

    _loadMoreGames();
  }

  

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMoreGames() async {
    if (_isLoading || !_hasMore) {
      return;
    }

    final requestVersion = _queryVersion;
    final searchPrefix = _searchText.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final games = await context
          .read<GamesNotifier>()
          .getAllGamesPaged(
            _currentPage,
            _pageSize,
            namePrefix: searchPrefix.isEmpty ? null : searchPrefix,
          );

      if (!mounted || requestVersion != _queryVersion) return;

      setState(() {
        _visibleGames.addAll(games);
        _currentPage++;
        _hasMore = games.length == _pageSize;
      });
    } catch (error) {
      if (!mounted || requestVersion != _queryVersion) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load games: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (_loadQueued) {
        _loadQueued = false;
        _loadMoreGames();
      }
    }
  }

  Future<void> _addGameToCollection(BoardGame game) async {
    final isAlreadyOwned = game.isOwned;
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
      await context.read<GamesNotifier>().addGameToCollection(game);

      if (!mounted) return;

      setState(() {
        final gameIndex = _visibleGames.indexWhere((g) => g.bggId == game.bggId);
        if (gameIndex != -1) {
          _visibleGames[gameIndex] = _visibleGames[gameIndex].copyWith(
            isOwned: true,
            detailsFetched: true,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${game.name} to your collection.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add ${game.name}: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _updatingGameIds.remove(game.bggId);
      });
    }
  }

  Future<void> _openBoardGameScreen(BoardGame game) async {
    final repository = context.read<SqlGamesRepository>();
    final service = context.read<BoardGameService>();

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

        final fetchedGame = await service.fetchBoardGameDetails(game.bggId);
        // Merge fetched details with user-specific flags from local game
        final gameToSave = fetchedGame.copyWith(
          isFavorite: game.isFavorite,
          isOwned: game.isOwned,
          timesPlayed: game.timesPlayed,
        );

        // Update database with full details
        //await widget.repository.persistGameWithRelations(gameToSave, isUpdate);
        await repository.updateGameWithRelations(gameToSave);
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
    final gameToShow = await repository.getGameById(game.bggId) ?? game;

    if (!mounted) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            BoardGameScreen(
              boardGame: gameToShow,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Collection'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: const [
          BggLinkButton(),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
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
            child: _visibleGames.isEmpty && !_isLoading
                ? const Center(child: Text('No games found.'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _visibleGames.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _visibleGames.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final game = _visibleGames[index];
                      final isUpdating = _updatingGameIds.contains(game.bggId);
                      final isOwned = game.isOwned;
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
                  ),
          ),
        ],
      ),
    );
  }
}
