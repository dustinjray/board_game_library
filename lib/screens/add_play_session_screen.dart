import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/play_session.dart';
import 'package:board_game_library/models/play_session_details.dart';
import 'package:board_game_library/models/play_session_score.dart';
import 'package:board_game_library/state/play_session_notifier.dart';
import 'package:board_game_library/widgets/score_entry_modal.dart';
import 'package:board_game_library/widgets/score_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddPlaySessionScreen extends StatefulWidget {
  final BoardGame boardGame;
  final PlaySessionDetails? existingDetails;

  const AddPlaySessionScreen({
    super.key,
    required this.boardGame,
    this.existingDetails,
  });

  @override
  State<AddPlaySessionScreen> createState() => _AddPlaySessionScreenState();
}

class _AddPlaySessionScreenState extends State<AddPlaySessionScreen> {
  late DateTime _datePlayed;
  late List<PlaySessionScore> _scores;
  late Set<int> _selectedExpansionIds;
  bool _useAllExpansions = false;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingDetails != null;
  int get _sessionId => widget.existingDetails?.session.id ?? 0;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      final details = widget.existingDetails!;
      _datePlayed = details.session.datePlayed;
      _scores = [...details.scores];
      _selectedExpansionIds = Set<int>.from(details.expansionIds);
      final allExpansionIds = widget.boardGame.expansions
          .map((e) => e.id)
          .toSet();
      _useAllExpansions =
          allExpansionIds.isNotEmpty && _selectedExpansionIds.containsAll(allExpansionIds);
    } else {
      _datePlayed = DateTime.now();
      _scores = [];
      _selectedExpansionIds = <int>{};
      _useAllExpansions = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PlaySessionNotifier>().loadAllPlayers();
    });
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _datePlayed,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_datePlayed),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _datePlayed = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Set<int> _excludedPlayerIdsForNew() {
    final ids = <int>{};
    for (final score in _scores) {
      if (score.playerId > 0) ids.add(score.playerId);
    }
    return ids;
  }

  Set<int> _excludedPlayerIdsForEdit(int editingIndex) {
    final ids = <int>{};
    for (int i = 0; i < _scores.length; i++) {
      if (i == editingIndex) continue;
      final id = _scores[i].playerId;
      if (id > 0) ids.add(id);
    }
    return ids;
  }

  Future<void> _addScore() async {
    final isPlayersLoading = context.read<PlaySessionNotifier>().isPlayersLoading;
    if (isPlayersLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Players are still loading. Please wait.')),
      );
      return;
    }

    final players = context.read<PlaySessionNotifier>().players;
    final newScore = await showScoreEntryModal(
      context: context,
      players: players,
      playSessionId: _sessionId,
      excludedPlayerIds: _excludedPlayerIdsForNew(),
    );

    if (newScore == null || !mounted) return;

    setState(() {
      _scores.add(newScore);
    });
  }

  Future<void> _editScore(int index) async {
    final isPlayersLoading = context.read<PlaySessionNotifier>().isPlayersLoading;
    if (isPlayersLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Players are still loading. Please wait.')),
      );
      return;
    }

    final players = context.read<PlaySessionNotifier>().players;
    final updated = await showScoreEntryModal(
      context: context,
      players: players,
      playSessionId: _sessionId,
      excludedPlayerIds: _excludedPlayerIdsForEdit(index),
      existingScore: _scores[index],
    );

    if (updated == null || !mounted) return;

    setState(() {
      _scores[index] = updated;
    });
  }

  void _removeScore(int index) {
    setState(() {
      _scores.removeAt(index);
    });
  }

  String? _validateScores() {
    if (_scores.isEmpty) {
      return 'Add at least one player score before saving.';
    }

    final usedPlayerIds = <int>{};
    final usedNewNames = <String>{};

    for (final score in _scores) {
      if (score.playerId > 0) {
        if (!usedPlayerIds.add(score.playerId)) {
          final name = score.player?.name ?? 'Player';
          return '$name appears more than once.';
        }
        continue;
      }

      final newName = score.player?.name.trim() ?? '';
      if (newName.isEmpty) {
        return 'A new player entry is missing a name.';
      }
      final normalized = newName.toLowerCase();
      if (!usedNewNames.add(normalized)) {
        return '$newName appears more than once.';
      }
    }

    return null;
  }

  Future<void> _save() async {
    final validationError = _validateScores();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final selectedExpansionIds = _useAllExpansions
          ? widget.boardGame.expansions.map((e) => e.id).toList(growable: false)
          : _selectedExpansionIds.toList(growable: false);

      final details = PlaySessionDetails(
        session: PlaySession(
          id: _sessionId,
          boardGameId: widget.boardGame.bggId,
          datePlayed: _datePlayed,
        ),
        scores: _scores,
        expansionIds: selectedExpansionIds,
      );

      await context.read<PlaySessionNotifier>().saveSession(
            details,
            widget.boardGame.bggId,
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Delete this play session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || widget.existingDetails == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<PlaySessionNotifier>().deleteSession(
            widget.existingDetails!.session,
            widget.boardGame.bggId,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final ampm = value.hour >= 12 ? 'PM' : 'AM';
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.month}/${value.day}/${value.year} $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expansions = widget.boardGame.expansions;
    final isPlayersLoading = context.select<PlaySessionNotifier, bool>(
      (notifier) => notifier.isPlayersLoading,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Play Session' : 'Add Play Session'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Date & Time'),
              subtitle: Text(_formatDateTime(_datePlayed)),
              leading: const Icon(Icons.schedule),
              trailing: const Icon(Icons.chevron_right),
              onTap: _isSaving ? null : _pickDateTime,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Player Scores',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isPlayersLoading) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 8),
                    Text(
                      'Loading players...',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_scores.isEmpty)
                    Text(
                      'No player scores added yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ..._scores.asMap().entries.map((entry) {
                    final index = entry.key;
                    final score = entry.value;
                    return ScoreRowWidget(
                      score: score,
                      onEdit: _isSaving ? null : () => _editScore(index),
                      onRemove: _isSaving ? null : () => _removeScore(index),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isSaving || isPlayersLoading ? null : _addScore,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Player Score'),
                  ),
                ],
              ),
            ),
          ),
          if (expansions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expansions Used',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _useAllExpansions,
                      title: const Text('All expansions'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _useAllExpansions = value ?? false;
                                if (_useAllExpansions) {
                                  _selectedExpansionIds = expansions
                                      .map((e) => e.id)
                                      .toSet();
                                }
                              });
                            },
                    ),
                    ...expansions.map((expansion) {
                      return CheckboxListTile(
                        value: _selectedExpansionIds.contains(expansion.id),
                        title: Text(expansion.name),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: _isSaving || _useAllExpansions
                            ? null
                            : (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedExpansionIds.add(expansion.id);
                                  } else {
                                    _selectedExpansionIds.remove(expansion.id);
                                  }
                                });
                              },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          if (_isEditMode) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Delete Session',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
