import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:board_game_library/state/games_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BoardGameFilter extends StatefulWidget {
  final BoardGameCriteria initialCriteria;
  final ValueChanged<BoardGameCriteria> onApply;
  final VoidCallback onClear;

  const BoardGameFilter({
    super.key,
    required this.initialCriteria,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<BoardGameFilter> createState() => _BoardGameFilterState();
}

class _BoardGameFilterState extends State<BoardGameFilter> {
  late final TextEditingController _minPlayersController;
  late final TextEditingController _maxPlayersController;
  late final TextEditingController _maxPlaytimeController;
  late final TextEditingController _ageController;
  bool? _isFavoriteFilter;
  bool? _isUnplayedFilter;
  bool? _isExpansionFilter;
  final Set<int> _selectedCategoryIds = {};
  final Set<int> _selectedMechanicIds = {};

  @override
  void initState() {
    super.initState();
    final initialCriteria = widget.initialCriteria;

    _minPlayersController = TextEditingController();
    _maxPlayersController = TextEditingController();
    _maxPlaytimeController = TextEditingController();
    _ageController = TextEditingController();

    _minPlayersController.text = initialCriteria.minPlayers?.toString() ?? '';
    _maxPlayersController.text = initialCriteria.maxPlayers?.toString() ?? '';
    _maxPlaytimeController.text = initialCriteria.maxPlaytime?.toString() ?? '';
    _ageController.text = initialCriteria.age?.toString() ?? '';

    _isFavoriteFilter = initialCriteria.isFavorite;
    _isUnplayedFilter = initialCriteria.isUnplayed;
    _isExpansionFilter = initialCriteria.isExpansion;

    _selectedCategoryIds.addAll(
      (initialCriteria.categories ?? const <BoardGameCategory>[]).map(
        (category) => category.id,
      ),
    );
    _selectedMechanicIds.addAll(
      (initialCriteria.mechanics ?? const <BoardGameMechanic>[]).map(
        (mechanic) => mechanic.id,
      ),
    );
  }

  @override
  void dispose() {
    _minPlayersController.dispose();
    _maxPlayersController.dispose();
    _maxPlaytimeController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  int? _parseInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return int.tryParse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mechanics = context.select<GamesNotifier, List<BoardGameMechanic>>(
      (notifier) => notifier.ownedMechanics.value,
    );
    final categories = context.select<GamesNotifier, List<BoardGameCategory>>(
      (notifier) => notifier.ownedCategories.value,
    );

    final sortedCategories = categories.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final sortedMechanics = mechanics.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Filters', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPlayersController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min players'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPlayersController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max players'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxPlaytimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max playtime'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Min age'),
            ),
            const SizedBox(height: 12),
            _buildBooleanFilter(
              label: 'Favorite',
              value: _isFavoriteFilter,
              onChanged: (value) => setState(() => _isFavoriteFilter = value),
            ),
            const SizedBox(height: 12),
            _buildBooleanFilter(
              label: 'Unplayed',
              value: _isUnplayedFilter,
              onChanged: (value) => setState(() => _isUnplayedFilter = value),
            ),
            const SizedBox(height: 12),
            _buildBooleanFilter(
              label: 'Expansion',
              value: _isExpansionFilter,
              onChanged: (value) => setState(() => _isExpansionFilter = value),
            ),
            const SizedBox(height: 12),
            if (sortedCategories.isNotEmpty)
              ExpansionTile(
                title: Text('Categories (${sortedCategories.length})'),
                children: sortedCategories
                    .map(
                      (category) => CheckboxListTile(
                        dense: true,
                        title: Text(category.name),
                        value: _selectedCategoryIds.contains(category.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedCategoryIds.add(category.id);
                            } else {
                              _selectedCategoryIds.remove(category.id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 12),
            if (sortedMechanics.isNotEmpty)
              ExpansionTile(
                title: Text('Mechanics (${sortedMechanics.length})'),
                children: sortedMechanics
                    .map(
                      (mechanic) => CheckboxListTile(
                        dense: true,
                        title: Text(mechanic.name),
                        value: _selectedMechanicIds.contains(mechanic.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedMechanicIds.add(mechanic.id);
                            } else {
                              _selectedMechanicIds.remove(mechanic.id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _minPlayersController.clear();
                        _maxPlayersController.clear();
                        _maxPlaytimeController.clear();
                        _ageController.clear();
                        _selectedCategoryIds.clear();
                        _selectedMechanicIds.clear();
                        _isFavoriteFilter = null;
                        _isExpansionFilter = false;
                        _isUnplayedFilter = null;
                      });
                      widget.onClear();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final criteria = BoardGameCriteria(
                        isOwned: true,
                        isExpansion: _isExpansionFilter,
                        isFavorite: _isFavoriteFilter,
                        isUnplayed: _isUnplayedFilter,
                        minPlayers: _parseInt(_minPlayersController.text),
                        maxPlayers: _parseInt(_maxPlayersController.text),
                        maxPlaytime: _parseInt(_maxPlaytimeController.text),
                        age: _parseInt(_ageController.text),
                        categories: _selectedCategoryIds.isEmpty
                            ? const []
                            : categories
                                  .where(
                                    (cat) =>
                                        _selectedCategoryIds.contains(cat.id),
                                  )
                                  .toList(),
                        mechanics: _selectedMechanicIds.isEmpty
                            ? const []
                            : mechanics
                                  .where(
                                    (mech) =>
                                        _selectedMechanicIds.contains(mech.id),
                                  )
                                  .toList(),
                      );
                      widget.onApply(criteria);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooleanFilter({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return DropdownButtonFormField<bool?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: const [
        DropdownMenuItem<bool?>(value: null, child: Text('Any')),
        DropdownMenuItem<bool?>(value: true, child: Text('Yes')),
        DropdownMenuItem<bool?>(value: false, child: Text('No')),
      ],
      onChanged: onChanged,
    );
  }
}
