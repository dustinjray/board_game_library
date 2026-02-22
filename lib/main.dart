import 'dart:async';

import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/data/repository/sql_games_repository.dart';
import 'package:flutter/material.dart';
import 'package:board_game_library/config/database_factory_init.dart';

import 'models/board_game.dart';
import 'util/json_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDatabaseFactory();
  final dbHelper = DatabaseHelper();
  final repository = SqlGamesRepository(dbHelper);

  await _seedRepositoryIfEmpty(repository);
  runApp(MainApp(repository: repository));
}

Future<void> _seedRepositoryIfEmpty(SqlGamesRepository repository) async {
  final existingCount = await repository.countGames();
  if (existingCount >= 167331) {
    print('Number of games already in repository: $existingCount');
    return; // Repository already has data, no need to seed
  }

  final gamesFromJson = await loadBoardGamesFromJsonAsset();
  print('Games loaded from JSON asset: ${gamesFromJson.length}');
  await repository.insertGamesBulk(gamesFromJson, chunkSize: 2000);
}

class MainApp extends StatelessWidget {
  final SqlGamesRepository repository;

  const MainApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BoardGameListPage(repository: repository),
    );
  }
}

class BoardGameListPage extends StatefulWidget {
  final SqlGamesRepository repository;

  const BoardGameListPage({super.key, required this.repository});

  @override
  State<BoardGameListPage> createState() => _BoardGameListPageState();
}

class _BoardGameListPageState extends State<BoardGameListPage> {
  late final Future<List<BoardGame>> _boardGamesFuture;

  @override
  void initState() {
    super.initState();
    _boardGamesFuture = widget.repository.getAllGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Board Games')),
      body: FutureBuilder<List<BoardGame>>(
        future: _boardGamesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load board games: ${snapshot.error}'),
              ),
            );
          }

          final boardGames = snapshot.data ?? const <BoardGame>[];
          if (boardGames.isEmpty) {
            return const Center(child: Text('No board games found.'));
          }

          return ListView.builder(
            itemCount: boardGames.length,
            itemBuilder: (context, index) {
              final game = boardGames[index];
              final yearText =
                  game.yearPublished != null ? '${game.yearPublished}' : 'Unknown year';

              return ListTile(
                title: Text(game.name),
                subtitle: Text(yearText),
              );
            },
          );
        },
      ),
    );
  }
}
