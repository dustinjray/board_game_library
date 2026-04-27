import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/widgets/bgg_link_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:board_game_library/state/games_notifier.dart';

class EditGameScreen extends StatefulWidget {
  const EditGameScreen({super.key, required this.boardGame});

  final BoardGame boardGame;


  @override
  State<EditGameScreen> createState() => _EditGameScreenState();
}

class _EditGameScreenState extends State<EditGameScreen> {
  bool _isDirty = false;
  bool _didUpdate = false;
  bool _isSaving = false;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _minPlayersController;
  late final TextEditingController _maxPlayersController;
  late final TextEditingController _minPlaytimeController;
  late final TextEditingController _maxPlaytimeController;
  late final TextEditingController _ageController;
  bool _isExpansion = false;
  bool _isOwned = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.boardGame.name);
    _descriptionController = TextEditingController(text: widget.boardGame.description);
    _minPlayersController = TextEditingController(text: widget.boardGame.minPlayers?.toString());
    _maxPlayersController = TextEditingController(text: widget.boardGame.maxPlayers?.toString());
    _minPlaytimeController = TextEditingController(text: widget.boardGame.minPlaytime?.toString());
    _maxPlaytimeController = TextEditingController(text: widget.boardGame.maxPlaytime?.toString());
    _ageController = TextEditingController(text: widget.boardGame.age?.toString());
    _isExpansion = widget.boardGame.isExpansion;
    _isOwned = widget.boardGame.isOwned;
    _isFavorite = widget.boardGame.isFavorite;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minPlayersController.dispose();
    _maxPlayersController.dispose();
    _minPlaytimeController.dispose();
    _maxPlaytimeController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.boardGame;
    // final theme = Theme.of(context);

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_didUpdate);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Game'),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop(_didUpdate);
            },
          ),
          actions: [
            const BggLinkButton(),
          ]
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (_) => setState(() => _isDirty = true),
              ),
              const SizedBox(height: 16.0),
              // TextField(
              //   controller: _descriptionController,
              //   decoration: const InputDecoration(labelText: 'Description'),
              //   maxLines: null,
              //   onChanged: (_) => setState(() => _isDirty = true),
              // ),
              // const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPlayersController,
                      decoration: const InputDecoration(labelText: 'Min Players'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() => _isDirty = true),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: TextField(
                      controller: _maxPlayersController,
                      decoration: const InputDecoration(labelText: 'Max Players'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() => _isDirty = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPlaytimeController,
                      decoration: const InputDecoration(labelText: 'Min Playtime (min)'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() => _isDirty = true),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: TextField(
                      controller: _maxPlaytimeController,
                      decoration: const InputDecoration(labelText: 'Max Playtime (min)'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() => _isDirty = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _isDirty = true),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: null,
                onChanged: (_) => setState(() => _isDirty = true),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _isExpansion,
                    onChanged: (value) => setState(() {
                      _isExpansion = value ?? false;
                      _isDirty = true;
                    }),
                  ),
                  const Text('Is Expansion'),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _isOwned,
                    onChanged: (value) => setState(() {
                      _isOwned = value ?? false;
                      _isDirty = true;
                    }),
                  ),
                  const Text('Owned'),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _isFavorite,
                    onChanged: (value) => setState(() {
                      _isFavorite = value ?? false;
                      _isDirty = true;
                    }),
                  ),
                  const Text('Favorite'),
                ],
              ),
              const SizedBox(height: 24.0),
            ],
          )
        ),
        floatingActionButton: _isDirty
          ? FloatingActionButton(
        onPressed: _isSaving ? null : () async {
          setState(() => _isSaving = true);
          final nav = Navigator.of(context);
          final gamesNotifier = context.read<GamesNotifier>();
          final messenger = ScaffoldMessenger.of(context);
          try {
            final updatedGame = game.copyWith(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              minPlayers: int.tryParse(_minPlayersController.text.trim()),
              maxPlayers: int.tryParse(_maxPlayersController.text.trim()),
              minPlaytime: int.tryParse(_minPlaytimeController.text.trim()),
              maxPlaytime: int.tryParse(_maxPlaytimeController.text.trim()),
              age: int.tryParse(_ageController.text.trim()),
              isExpansion: _isExpansion,
              isOwned: _isOwned,
              isFavorite: _isFavorite,
            );

            await gamesNotifier.updateGame(updatedGame);

            setState(() {
              _isDirty = false;
              _didUpdate = true;
            });
            nav.pop(true);
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(content: Text('Error saving game: $e')),
              );
            }
          } finally {
            if (mounted) setState(() => _isSaving = false);
          }
        },
        child: const Icon(Icons.save),
      )
    : null,
      )
    );
  }
}