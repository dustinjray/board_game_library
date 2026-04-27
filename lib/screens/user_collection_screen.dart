 import 'dart:async';

import 'package:board_game_library/enums/game_sort_option.dart';
import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:board_game_library/screens/add_to_collection_screen.dart';
import 'package:board_game_library/screens/board_game_screen.dart';
import 'package:board_game_library/state/games_notifier.dart';
import 'package:board_game_library/widgets/bgg_link_button.dart';
import 'package:board_game_library/widgets/board_game_filter.dart';
import 'package:board_game_library/widgets/board_game_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserCollectionScreen extends StatefulWidget {
  const UserCollectionScreen({super.key});

  @override
  State<UserCollectionScreen> createState() => _UserCollectionScreenState();
}

class _UserCollectionScreenState extends State<UserCollectionScreen> {
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

  BoardGameCriteria _activeCriteria = const BoardGameCriteria(
    isOwned: true,
    isExpansion: false,
  );

  bool get _hasActiveDrawerFilters {
    return _activeCriteria.minPlayers != null ||
        _activeCriteria.maxPlayers != null ||
        _activeCriteria.maxPlaytime != null ||
        _activeCriteria.age != null ||
        _activeCriteria.isFavorite != null ||
        _activeCriteria.isUnplayed != null ||
        _activeCriteria.isExpansion != false ||
        (_activeCriteria.categories?.isNotEmpty ?? false) ||
        (_activeCriteria.mechanics?.isNotEmpty ?? false);
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();

    _searchController.addListener(_onSearchChanged);

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        _loadMoreOwnedGames();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GamesNotifier>().loadOwnedCategories();
      context.read<GamesNotifier>().loadOwnedMechanics();
      _loadMoreOwnedGames();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        _searchText = _searchController.text;
      });
      _resetAndReload();
    });
  }

  void _onSortOptionSelected(GameSortOption option) {
    if (option == _activeCriteria.sortOption) return;

    setState(() {
      _activeCriteria = _activeCriteria.copyWith(sortOption: option);
      _queryVersion++;
    });
    _resetAndReload();
  }

  Future<void> _resetAndReload() async {
    if (!mounted) return;

    setState(() {
      _currentPage = 0;
      _visibleGames = <BoardGame>[];
      _hasMore = true;
      _queryVersion++;
    });

    if (_isLoading) {
      _loadQueued = true;
      return;
    }

    await _loadMoreOwnedGames();
  }

  Future<void> _loadMoreOwnedGames() async {
    if (_isLoading || !_hasMore) {
      return;
    }

    final requestVersion = _queryVersion;
    final searchPrefix = _searchText.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final games = await context.read<GamesNotifier>().getOwnedGamesPaged(
        _currentPage,
        _pageSize,
        namePrefix: searchPrefix.isEmpty ? null : searchPrefix,
        criteria: _activeCriteria,
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
        SnackBar(content: Text('Failed to load your collection: $error')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (_loadQueued) {
        _loadQueued = false;
        _loadMoreOwnedGames();
      }
    }
  }

  Future<void> _openAddToCollectionScreen() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddToCollectionScreen()),
    );

    if (!mounted) return;

    await context.read<GamesNotifier>().loadOwnedCategories();
    await context.read<GamesNotifier>().loadOwnedMechanics();
    await _resetAndReload();
  }

  Future<void> _openBoardGameScreen(BoardGame game) async {
    final gameWithDetails = await context
        .read<GamesNotifier>()
        .ensureGameDetailsLoaded(game.bggId);
    if (gameWithDetails == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load game details from database.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    final hasChanges = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BoardGameScreen(boardGame: gameWithDetails),
      ),
    );

    if (!mounted) return;

    if (hasChanges == true) {
      await _resetAndReload();
    }
  }

  void _applyFilters(BoardGameCriteria criteria) {
    setState(() {
      _activeCriteria = criteria;
    });
    _resetAndReload();
  }

  void _clearFilters() {
    setState(() {
      _activeCriteria = const BoardGameCriteria(
        isOwned: true,
        isExpansion: false,
      );
    });
    _resetAndReload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('My Collection'),
            if (_hasActiveDrawerFilters) ...[
              const SizedBox(width: 8),
              const Tooltip(
                message: 'Filters active',
                child: Icon(Icons.filter_alt, size: 18),
              ),
            ],
          ],
        ),
        actions: [
          const BggLinkButton(),
        ],
      ),
      drawer: BoardGameFilter(
        initialCriteria: _activeCriteria,
        onApply: _applyFilters,
        onClear: _clearFilters,
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                PopupMenuButton<GameSortOption>(
                  tooltip: 'Sort games',
                  icon: const Icon(Icons.sort),
                  initialValue: _activeCriteria.sortOption,
                  onSelected: _onSortOptionSelected,
                  itemBuilder: (context) => GameSortOption.values
                      .map(
                        (option) => PopupMenuItem<GameSortOption>(
                          value: option,
                          child: Row(
                            children: [
                              Expanded(child: Text(option.label)),
                              if (option == _activeCriteria.sortOption)
                                const Icon(Icons.check, size: 16),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _activeCriteria.sortOption.label,
                    overflow: TextOverflow.ellipsis,
                  )
                )
              ]
            )
          ),
          Expanded(
            child: _visibleGames.isEmpty && !_isLoading
                ? const Center(child: Text('No owned games found.'))
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
                      return BoardGameTile(
                        boardGame: game,
                        onTap: () => _openBoardGameScreen(game),
                      );
                    },
                  ),
          ),
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openAddToCollectionScreen,
                child: const Text('Add to Collection'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
