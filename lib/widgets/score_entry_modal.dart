import 'package:board_game_library/models/play_session_score.dart';
import 'package:board_game_library/models/player.dart';
import 'package:flutter/material.dart';

Future<PlaySessionScore?> showScoreEntryModal({
  required BuildContext context,
  required List<Player> players,
  required int playSessionId,
  required Set<int> excludedPlayerIds,
  PlaySessionScore? existingScore,
}) {
  return showDialog<PlaySessionScore>(
    context: context,
    builder: (context) => ScoreEntryModal(
      players: players,
      playSessionId: playSessionId,
      excludedPlayerIds: excludedPlayerIds,
      existingScore: existingScore,
    ),
  );
}

class ScoreEntryModal extends StatefulWidget {
  final List<Player> players;
  final int playSessionId;
  final Set<int> excludedPlayerIds;
  final PlaySessionScore? existingScore;

  const ScoreEntryModal({
    super.key,
    required this.players,
    required this.playSessionId,
    required this.excludedPlayerIds,
    this.existingScore,
  });

  @override
  State<ScoreEntryModal> createState() => _ScoreEntryModalState();
}

class _ScoreEntryModalState extends State<ScoreEntryModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _scoreController;

  Player? _selectedPlayer;
  bool _noScore = false;
  bool _isWinner = false;
  String? _errorText;

  bool get _isEditMode => widget.existingScore != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _scoreController = TextEditingController();

    final existing = widget.existingScore;
    if (existing != null) {
      _isWinner = existing.isWinner;
      _noScore = !existing.hasScore;
      _scoreController.text = existing.scoreInputValue;

      if (existing.playerId > 0) {
        final match = widget.players
            .where((p) => p.id == existing.playerId)
            .cast<Player?>()
            .firstWhere((p) => p != null, orElse: () => null);
        _selectedPlayer = match;
        _nameController.text = match?.name ?? existing.player?.name ?? '';
      } else {
        _nameController.text = existing.player?.name ?? '';
      }
    }

    _nameController.addListener(() {
      if (_selectedPlayer == null) return;
      final current = _nameController.text.trim().toLowerCase();
      final selected = _selectedPlayer!.name.trim().toLowerCase();
      if (current != selected) {
        setState(() {
          _selectedPlayer = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  List<Player> get _availablePlayers {
    final query = _nameController.text.trim().toLowerCase();

    final sorted = [...widget.players]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return sorted.where((player) {
      final id = player.id;
      if (id == null) return false;
      if (widget.excludedPlayerIds.contains(id)) return false;
      if (query.isEmpty) return true;
      return player.name.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  void _onSelectPlayer(Player player) {
    setState(() {
      _selectedPlayer = player;
      _nameController.text = player.name;
      _errorText = null;
    });
  }

  bool _nameExists(String normalizedName) {
    for (final player in widget.players) {
      if (player.name.trim().toLowerCase() == normalizedName) {
        return true;
      }
    }
    return false;
  }

  void _confirm() {
    final scoreRaw = _scoreController.text.trim();
    final parsedScore = scoreRaw.isEmpty ? null : int.tryParse(scoreRaw);

    if (!_noScore && scoreRaw.isNotEmpty && parsedScore == null) {
      setState(() {
        _errorText = 'Score must be a valid integer, or mark No score.';
      });
      return;
    }

    if (_selectedPlayer != null) {
      final selectedId = _selectedPlayer!.id;
      if (selectedId == null || selectedId <= 0) {
        setState(() {
          _errorText = 'Selected player is invalid.';
        });
        return;
      }

      Navigator.of(context).pop(
        PlaySessionScore(
          playSessionId: widget.playSessionId,
          playerId: selectedId,
          score: _noScore ? null : parsedScore,
          isWinner: _isWinner,
          player: _selectedPlayer,
        ),
      );
      return;
    }

    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() {
        _errorText = 'Type a player name or select an existing player.';
      });
      return;
    }

    final normalized = newName.toLowerCase();
    if (_nameExists(normalized)) {
      setState(() {
        _errorText =
            'A player with that name already exists. Select them or use a unique name.';
      });
      return;
    }

    Navigator.of(context).pop(
      PlaySessionScore(
        playSessionId: widget.playSessionId,
        playerId: 0,
        score: _noScore ? null : parsedScore,
        isWinner: _isWinner,
        player: Player(name: newName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availablePlayers = _availablePlayers;

    return AlertDialog(
      title: Text(_isEditMode ? 'Edit Player Score' : 'Add Player Score'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Player name',
                hintText: 'Type to filter existing players or add a new name',
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availablePlayers.length,
                itemBuilder: (context, index) {
                  final player = availablePlayers[index];
                  final selected = _selectedPlayer?.id == player.id;
                  return ListTile(
                    dense: true,
                    title: Text(player.name),
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () => _onSelectPlayer(player),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _scoreController,
                    enabled: !_noScore,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Score'),
                  ),
                ),
                const SizedBox(width: 12),
                Checkbox(
                  value: _noScore,
                  onChanged: (value) {
                    setState(() {
                      _noScore = value ?? false;
                      if (_noScore) _scoreController.clear();
                      _errorText = null;
                    });
                  },
                ),
                const Text('No score'),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _isWinner,
                  onChanged: (value) {
                    setState(() {
                      _isWinner = value ?? false;
                    });
                  },
                ),
                const Text('Winner'),
              ],
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _confirm,
          child: Text(_isEditMode ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
