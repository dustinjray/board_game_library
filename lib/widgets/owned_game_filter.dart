import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:flutter/material.dart';

class OwnedGameFilterDrawer extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController minPlayersController;
  final TextEditingController maxPlayersController;
  final TextEditingController maxPlaytimeController;
  final TextEditingController ageController;
  final bool? isFavoriteFilter;
  final bool? isUnplayedFilter;
  final bool? isExpansionFilter;
  final Future<List<BoardGameCategory>> ownedCategoriesFuture;
  final Future<List<BoardGameMechanic>> ownedMechanicsFuture;
  final List<BoardGameCategory> ownedCategories;
  final List<BoardGameMechanic> ownedMechanics;
  final Set<int> selectedCategoryIds;
  final Set<int> selectedMechanicIds;
  final ValueChanged<bool?> onFavoriteChanged;
  final ValueChanged<bool?> onUnplayedChanged;
  final ValueChanged<bool?> onExpansionChanged;
  final void Function(int id, bool selected) onCategoryToggled;
  final void Function(int id, bool selected) onMechanicToggled;
  final VoidCallback onClear;
  final VoidCallback onApply;

  const OwnedGameFilterDrawer({
    super.key,
    required this.nameController,
    required this.minPlayersController,
    required this.maxPlayersController,
    required this.maxPlaytimeController,
    required this.ageController,
    required this.isFavoriteFilter,
    required this.isUnplayedFilter,
    required this.isExpansionFilter,
    required this.ownedCategoriesFuture,
    required this.ownedMechanicsFuture,
    required this.ownedCategories,
    required this.ownedMechanics,
    required this.selectedCategoryIds,
    required this.selectedMechanicIds,
    required this.onFavoriteChanged,
    required this.onUnplayedChanged,
    required this.onExpansionChanged,
    required this.onCategoryToggled,
    required this.onMechanicToggled,
    required this.onClear,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Filters', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name contains',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minPlayersController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min players',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxPlayersController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max players',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxPlaytimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max playtime',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Min age',
              ),
            ),
            const SizedBox(height: 12),
            _buildBooleanFilter(
              label: 'Favorite',
              value: isFavoriteFilter,
              onChanged: onFavoriteChanged,
            ),
            const SizedBox(height: 12),
            _buildBooleanFilter(
              label: 'Unplayed',
              value: isUnplayedFilter,
              onChanged: onUnplayedChanged,
            ),
            const SizedBox(height: 12),
            _buildBooleanFilter(
              label: 'Expansion',
              value: isExpansionFilter,
              onChanged: onExpansionChanged,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<BoardGameCategory>>(
              future: ownedCategoriesFuture,
              builder: (context, snapshot) {
                final categories = (snapshot.data ?? ownedCategories).toList()
                  ..sort(
                    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );
                if (categories.isEmpty) {
                  return const SizedBox.shrink();
                }
                return ExpansionTile(
                  title: Text('Categories (${categories.length})'),
                  children: categories
                      .map(
                        (category) => CheckboxListTile(
                          dense: true,
                          title: Text(category.name),
                          value: selectedCategoryIds.contains(category.id),
                          onChanged: (checked) =>
                              onCategoryToggled(category.id, checked == true),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<BoardGameMechanic>>(
              future: ownedMechanicsFuture,
              builder: (context, snapshot) {
                final mechanics = (snapshot.data ?? ownedMechanics).toList()
                  ..sort(
                    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );
                if (mechanics.isEmpty) {
                  return const SizedBox.shrink();
                }
                return ExpansionTile(
                  title: Text('Mechanics (${mechanics.length})'),
                  children: mechanics
                      .map(
                        (mechanic) => CheckboxListTile(
                          dense: true,
                          title: Text(mechanic.name),
                          value: selectedMechanicIds.contains(mechanic.id),
                          onChanged: (checked) =>
                              onMechanicToggled(mechanic.id, checked == true),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClear,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApply,
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
      value: value,
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
