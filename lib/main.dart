import 'dart:async';

import 'package:board_game_library/data/dao/categories_dao.dart';
import 'package:board_game_library/data/dao/expansions_dao.dart';
import 'package:board_game_library/data/dao/games_dao.dart';
import 'package:board_game_library/data/dao/mechanics_dao.dart';
import 'package:board_game_library/data/dao/play_session_dao.dart';
import 'package:board_game_library/data/dao/play_session_expansion_dao.dart';
import 'package:board_game_library/data/dao/play_session_score_dao.dart';
import 'package:board_game_library/data/dao/player_dao.dart';
import 'package:board_game_library/data/dao/sql_categories_dao.dart';
import 'package:board_game_library/data/dao/sql_expansions_dao.dart';
import 'package:board_game_library/data/dao/sql_games_dao.dart';
import 'package:board_game_library/data/dao/sql_mechanics_dao.dart';
import 'package:board_game_library/data/dao/sql_play_session_dao.dart';
import 'package:board_game_library/data/dao/sql_play_session_expansion_dao.dart';
import 'package:board_game_library/data/dao/sql_play_session_score_dao.dart';
import 'package:board_game_library/data/dao/sql_player_dao.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/data/repository/sql_games_repository.dart';
import 'package:board_game_library/data/repository/sql_play_session_repository.dart';
import 'package:board_game_library/screens/user_collection_screen.dart';
import 'package:board_game_library/services/board_game_service.dart';
import 'package:board_game_library/state/games_notifier.dart';
import 'package:board_game_library/state/play_session_notifier.dart';
import 'package:flutter/material.dart';
import 'package:board_game_library/config/database_factory_init.dart';
import 'package:provider/provider.dart';

import 'util/json_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDatabaseFactory();
  final dbHelper = DatabaseHelper();

  // Initialize all DAOs
  final GamesDAO gamesDAO = SqlGamesDAO(dbHelper);
  final CategoriesDAO categoriesDAO = SqlCategoriesDAO(dbHelper);
  final MechanicsDAO mechanicsDAO = SqlMechanicsDAO(dbHelper);
  final ExpansionsDAO expansionsDAO = SqlExpansionsDAO(dbHelper);
  final PlayerDAO playerDAO = SqlPlayerDAO(dbHelper);
  final PlaySessionDAO playSessionDAO = SqlPlaySessionDAO(dbHelper);
  final PlaySessionExpansionDAO playSessionExpansionDAO =
      SqlPlaySessionExpansionDAO(dbHelper);
  final PlaySessionScoreDAO playSessionScoreDAO = SqlPlaySessionScoreDAO(
    dbHelper,
  );

  // Initialize repository with all DAOs
  final service = BoardGameService();
  final gamesRepository = SqlGamesRepository(
    dbHelper,
    gamesDAO,
    categoriesDAO,
    mechanicsDAO,
    expansionsDAO,
    service,
  );
  final playSessionRepository = SqlPlaySessionRepository(
    playSessionDAO,
    playSessionExpansionDAO,
    playSessionScoreDAO,
    playerDAO,
  );

  await _seedRepositoryIfEmpty(gamesRepository);
  runApp(
    MultiProvider(
      providers: [
        // Provider<DatabaseHelper>.value(value: dbHelper),
        // Provider<GamesDAO>.value(value: gamesDAO),
        // Provider<CategoriesDAO>.value(value: categoriesDAO),
        // Provider<MechanicsDAO>.value(value: mechanicsDAO),
        // Provider<ExpansionsDAO>.value(value: expansionsDAO),
        Provider<SqlGamesRepository>.value(value: gamesRepository),
        Provider<SqlPlaySessionRepository>.value(value: playSessionRepository),
        // Provider<BoardGameService>.value(value: service),
        ChangeNotifierProvider(
          create: (context) => GamesNotifier(gamesRepository),
        ),
        ChangeNotifierProvider(
          create: (context) => PlaySessionNotifier(playSessionRepository),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

Future<void> _seedRepositoryIfEmpty(SqlGamesRepository repository) async {
  final existingCount = await repository.countGames();
  if (existingCount >= 1) {
    print('Number of games already in repository: $existingCount');
    return; // Repository already has data, no need to seed
  }

  final gamesFromJson = await loadBoardGamesFromJsonAsset();
  print('Games loaded from JSON asset: ${gamesFromJson.length}');
  await repository.insertGamesBulk(gamesFromJson, chunkSize: 2000);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const UserCollectionScreen());
  }
}
