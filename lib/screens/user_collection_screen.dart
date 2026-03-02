import 'package:board_game_library/data/repository/games_repository.dart';
import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:board_game_library/screens/add_to_collection_screen.dart';
import 'package:board_game_library/screens/board_game_screen.dart';
import 'package:board_game_library/services/board_game_service.dart';
import 'package:board_game_library/widgets/board_game_tile.dart';
import 'package:board_game_library/widgets/owned_game_filter.dart';
import 'package:flutter/material.dart';

class UserCollectionScreen extends StatefulWidget {
  final GamesRepository repository;
  final BoardGameService service;

  const UserCollectionScreen({super.key, required this.repository, required this.service});

  @override
  State<UserCollectionScreen> createState() => _UserCollectionScreenState();
}

class _UserCollectionScreenState extends State<UserCollectionScreen> {
  late Future<List<BoardGame>> _ownedGamesFuture;
  late final TextEditingController _nameController;
  late final TextEditingController _minPlayersController;
  late final TextEditingController _maxPlayersController;
  late final TextEditingController _maxPlaytimeController;
  late final TextEditingController _ageController;
  late Future<List<BoardGameCategory>> _ownedCategoriesFuture;
  late Future<List<BoardGameMechanic>> _ownedMechanicsFuture;
  List<BoardGameCategory> _ownedCategories = const [];
  List<BoardGameMechanic> _ownedMechanics = const [];
  final Set<int> _selectedCategoryIds = <int>{};
  final Set<int> _selectedMechanicIds = <int>{};
  bool? _isFavoriteFilter;
  bool? _isExpansionFilter = false;
  bool? _isUnplayedFilter;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _minPlayersController = TextEditingController();
    _maxPlayersController = TextEditingController();
    _maxPlaytimeController = TextEditingController();
    _ageController = TextEditingController();
    _ownedCategoriesFuture = widget.repository
        .filterOwnedCategories()
        .then((value) => _ownedCategories = value);
    _ownedMechanicsFuture = widget.repository
        .filterOwnedMechanics()
        .then((value) => _ownedMechanics = value);
    _loadOwnedGames();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minPlayersController.dispose();
    _maxPlayersController.dispose();
    _maxPlaytimeController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _loadOwnedGames() {
    _ownedGamesFuture = widget.repository.searchByCriteria(
      const BoardGameCriteria(isOwned: true, isExpansion: false),
    );
  }

  int? _parseInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return int.tryParse(trimmed);
  }

  void _applyFilters() {
    final criteria = BoardGameCriteria(
      isOwned: true,
      isExpansion: _isExpansionFilter,
      isFavorite: _isFavoriteFilter,
      isUnplayed: _isUnplayedFilter,
      nameLike: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      minPlayers: _parseInt(_minPlayersController.text),
      maxPlayers: _parseInt(_maxPlayersController.text),
      maxPlaytime: _parseInt(_maxPlaytimeController.text),
      age: _parseInt(_ageController.text),
      categories: _selectedCategoryIds.isEmpty
          ? const []
          : _ownedCategories
              .where((category) => _selectedCategoryIds.contains(category.id))
              .toList(),
      mechanics: _selectedMechanicIds.isEmpty
          ? const []
          : _ownedMechanics
              .where((mechanic) => _selectedMechanicIds.contains(mechanic.id))
              .toList(),
    );

    setState(() {
      _ownedGamesFuture = widget.repository.searchByCriteria(criteria);
    });
  }

  void _clearFilters() {
    setState(() {
      _nameController.clear();
      _minPlayersController.clear();
      _maxPlayersController.clear();
      _maxPlaytimeController.clear();
      _ageController.clear();
      _selectedCategoryIds.clear();
      _selectedMechanicIds.clear();
      _isFavoriteFilter = null;
      _isExpansionFilter = false;
      _isUnplayedFilter = null;
      _loadOwnedGames();
    });
  }

  Future<void> _openAddToCollectionScreen() async {
    final hasChanges = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            AddToCollectionScreen(
              repository: widget.repository,
              service: widget.service,
            ),
      ),
    );

    if (hasChanges == true) {
      setState(() {
        _loadOwnedGames();
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
    final gameToShow = await widget.repository.getGameById(game.bggId) ?? game;

    if (!mounted) return;
    print('Opening details for ${gameToShow.name} (BGG ID: ${gameToShow.bggId})');

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
        _loadOwnedGames();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Collection')),
      drawer: OwnedGameFilterDrawer(
        nameController: _nameController,
        minPlayersController: _minPlayersController,
        maxPlayersController: _maxPlayersController,
        maxPlaytimeController: _maxPlaytimeController,
        ageController: _ageController,
        isFavoriteFilter: _isFavoriteFilter,
        isUnplayedFilter: _isUnplayedFilter,
        isExpansionFilter: _isExpansionFilter,
        ownedCategoriesFuture: _ownedCategoriesFuture,
        ownedMechanicsFuture: _ownedMechanicsFuture,
        ownedCategories: _ownedCategories,
        ownedMechanics: _ownedMechanics,
        selectedCategoryIds: _selectedCategoryIds,
        selectedMechanicIds: _selectedMechanicIds,
        onFavoriteChanged: (value) => setState(() => _isFavoriteFilter = value),
        onUnplayedChanged: (value) => setState(() => _isUnplayedFilter = value),
        onExpansionChanged: (value) => setState(() => _isExpansionFilter = value),
        onCategoryToggled: (id, selected) {
          setState(() {
            if (selected) {
              _selectedCategoryIds.add(id);
            } else {
              _selectedCategoryIds.remove(id);
            }
          });
        },
        onMechanicToggled: (id, selected) {
          setState(() {
            if (selected) {
              _selectedMechanicIds.add(id);
            } else {
              _selectedMechanicIds.remove(id);
            }
          });
        },
        onClear: () {
          _clearFilters();
          Navigator.of(context).pop();
        },
        onApply: () {
          _applyFilters();
          Navigator.of(context).pop();
        },
      ),
      body: FutureBuilder<List<BoardGame>>(
        future: _ownedGamesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load your collection: ${snapshot.error}',
                ),
              ),
            );
          }

          final ownedGames = snapshot.data ?? const <BoardGame>[];
          if (ownedGames.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Your collection is empty.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _openAddToCollectionScreen,
                      child: const Text('Add to Collection'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: ownedGames.length,
                  itemBuilder: (context, index) {
                    final game = ownedGames[index];
                    return BoardGameTile(
                      boardGame: game,
                      onTap: () => _openBoardGameScreen(game),
                    );
                  },
                ),
              ),
              Padding(
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
          );
        },
      ),
    );
  }
}

