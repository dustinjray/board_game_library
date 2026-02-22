import 'dart:io';

import 'package:board_game_library/config/database_factory_init.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/data/repository/sql_games_repository.dart';
import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;
  late SqlGamesRepository repository;
  late Directory tempDbDir;
  late String testDbPath;
  late String seededDbPath;

  setUpAll(() async {
    await initializeDatabaseFactory();
    tempDbDir = await Directory.systemTemp.createTemp('board_game_library_repo_test_db_');
    testDbPath = p.join(tempDbDir.path, 'sql_games_repository_test_database.db');
    seededDbPath = p.join(tempDbDir.path, 'sql_games_repository_seed_database.db');

    DatabaseHelper.setDatabasePathOverrideForTesting(seededDbPath);
    helper = DatabaseHelper();
    await helper.close();

    final seedFile = File(seededDbPath);
    if (await seedFile.exists()) {
      await seedFile.delete();
    }

    await _buildSeededDatabaseFromSql(
      helper: helper,
      sqlPath: 'test/resources/sql/seed_sql_games_repository_test_db.sql',
    );
  });

  setUp(() async {
    helper = DatabaseHelper();
    await helper.close();

    final dbFile = File(testDbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    await File(seededDbPath).copy(testDbPath);
    DatabaseHelper.setDatabasePathOverrideForTesting(testDbPath);

    repository = SqlGamesRepository(helper);
  });

  tearDownAll(() async {
    try {
      await helper.close();
    } catch (e) {
      // Helper was never initialized if all tests were skipped
    }
    DatabaseHelper.setDatabasePathOverrideForTesting(null);

    if (await tempDbDir.exists()) {
      await tempDbDir.delete(recursive: true);
    }
  });

  group('SqlGamesRepository', () {
    test('countGames() counts total games in database', () async {
      final expected = 6; // Based on the seed SQL file
      final actual = await repository.countGames();
      expect(actual, expected);
    });

    test('insertGamesBulk() inserts multiple board games', () async {
      final games = [
        _sampleGame(bggId: 900001, name: 'Bulk Game 1'),
        _sampleGame(bggId: 900002, name: 'Bulk Game 2'),
      ];

      await repository.insertGamesBulk(games);

      final allGames = await repository.getAllGames();
      expect(allGames.length, 8);
      expect(allGames.any((game) => game.bggId == 900001), isTrue);
      expect(allGames.any((game) => game.bggId == 900002), isTrue);
    });

    test('getAllGames() gets all games from the database', () async {
      final expectedGames = _getExpectedGamesFromSeed();
      final actualGames = await repository.getAllGames();
      expect(actualGames.length, expectedGames.length);
      for (final expected in expectedGames) {
        final match = actualGames.firstWhere((game) => game.bggId == expected.bggId, orElse: () => throw Exception('Game with bggId ${expected.bggId} not found'));
        expect(match.name, expected.name);
        expect(match.yearPublished, expected.yearPublished);
        expect(match.isExpansion, expected.isExpansion);
        expect(match.categories, isEmpty);
        expect(match.mechanics, isEmpty);
        expect(match.expansions, isEmpty);
      }
    });

    test('getGameById() gets a game by its ID', () async {
      final expected = BoardGame(bggId: 295895, name: 'Distilled', yearPublished: 2023, isExpansion: false);
      final actual = await repository.getGameById(295895);
      expect(actual.bggId, expected.bggId);
      expect(actual.name, expected.name);
      expect(actual.yearPublished, expected.yearPublished);
      expect(actual.isExpansion, expected.isExpansion);
      expect(actual.categories.length, 1);
      expect(actual.categories.first.id, 1002);
      expect(actual.mechanics.length, 1);
      expect(actual.mechanics.first.id, 2002);
      expect(actual.expansions, isEmpty);
    });

    test('insertGame() successfully inserts a board game', () async {
      final expectedGame = _sampleGame();
      await repository.insertGame(expectedGame);
      final actualGame = await repository.getGameById(expectedGame.bggId);
      expect(actualGame.bggId, expectedGame.bggId);
      expect(actualGame.name, expectedGame.name);
    });

    test('insertGameWithRelations() inserts a board game by id with mechanics, categories, and expansions', () async {
      final expected = _sampleGame(
        bggId: 900010,
        name: 'Insert With Relations',
        categories: [_sampleCategory(id: 999001, name: 'Unit Test Category')],
        mechanics: [_sampleMechanic(id: 999001, name: 'Unit Test Mechanic')],
        expansions: [_sampleExpansion(id: 999001, name: 'Unit Test Expansion')],
      );

      await repository.insertGameWithRelations(expected);

      final actual = await helper.getBoardGameWithRelationsById(expected.bggId);
      expect(actual, isNotNull);
      final actualGame = actual!;
      expect(actualGame.bggId, expected.bggId);
      expect(actualGame.categories.length, expected.categories.length);
      expect(actualGame.mechanics.length, expected.mechanics.length);
      expect(actualGame.expansions.length, expected.expansions.length);
      expect(actualGame.categories.first.id, expected.categories.first.id);
      expect(actualGame.categories.first.name, expected.categories.first.name);
      expect(actualGame.mechanics.first.id, expected.mechanics.first.id);
      expect(actualGame.mechanics.first.name, expected.mechanics.first.name);
      expect(actualGame.expansions.first.id, expected.expansions.first.id);
      expect(actualGame.expansions.first.name, expected.expansions.first.name);
    });

    test('updateGame() updates a board game', () async {
      final initial = _sampleGame(bggId: 900020, name: 'Before Update');
      await repository.insertGame(initial);

      final updated = initial.copyWith(
        name: 'After Update',
        yearPublished: 2024,
        minPlayers: 2,
        maxPlayers: 5,
      );

      await repository.updateGame(updated);

      final actual = await repository.getGameById(updated.bggId);
      expect(actual.name, 'After Update');
      expect(actual.yearPublished, 2024);
      expect(actual.minPlayers, 2);
      expect(actual.maxPlayers, 5);
    });

    test('updateGameWithRelations() updates relations with sync behavior', () async {
      final initial = _sampleGame(
        bggId: 900030,
        name: 'Before Relation Update',
        categories: [_sampleCategory(id: 999101, name: 'Category A')],
        mechanics: [_sampleMechanic(id: 999201, name: 'Mechanic A')],
        expansions: [_sampleExpansion(id: 999301, name: 'Expansion A')],
      );

      await repository.insertGameWithRelations(initial);

      final updated = initial.copyWith(
        name: 'After Relation Update',
        categories: [_sampleCategory(id: 999102, name: 'Category B')],
        mechanics: [_sampleMechanic(id: 999202, name: 'Mechanic B')],
        expansions: [_sampleExpansion(id: 999302, name: 'Expansion B')],
      );

      await repository.updateGameWithRelations(updated);

      final actual = await helper.getBoardGameWithRelationsById(updated.bggId);
      expect(actual, isNotNull);
      final actualGame = actual!;
      expect(actualGame.name, 'After Relation Update');
      expect(actualGame.categories.length, 1);
      expect(actualGame.categories.first.id, 999102);
      expect(actualGame.mechanics.length, 1);
      expect(actualGame.mechanics.first.id, 999202);
      expect(actualGame.expansions.length, 1);
      expect(actualGame.expansions.first.id, 999302);
    });

    test('deleteGame() deletes a game by its ID', () async {
      final gameToDelete = _sampleGame(bggId: 999999, name: 'Game To Delete');
      await repository.insertGame(gameToDelete);
      final inserted = await repository.getGameById(gameToDelete.bggId);
      expect(inserted.bggId, gameToDelete.bggId);

      await repository.deleteGame(gameToDelete);
      expect(
        () => repository.getGameById(gameToDelete.bggId),
        throwsA(isA<Exception>()),
      );
    });

    test('searchByCriteria() finds games with specific criteria', () async {
      final criteria = BoardGameCriteria(
        isOwned: true,
        nameLike: 'Distilled',
        categories: [_sampleCategory(id: 1002, name: 'Economic')],
        mechanics: [_sampleMechanic(id: 2002, name: 'Hand Management')],
      );

      final results = await repository.searchByCriteria(criteria);

      expect(results.length, 1);
      expect(results.first.bggId, 295895);
      expect(results.first.name, 'Distilled');
    });

    test('filterOwnedCategories() returns distinct categories for owned games', () async {
      final categories = await repository.filterOwnedCategories();

      expect(categories.length, 3);
      expect(categories.any((category) => category.id == 1001 && category.name == 'Strategy'), isTrue);
      expect(categories.any((category) => category.id == 1002 && category.name == 'Economic'), isTrue);
      expect(categories.any((category) => category.id == 1003 && category.name == 'Cooperative'), isTrue);
    });

    test('filterOwnedMechanics() returns distinct mechanics for owned games', () async {
      final mechanics = await repository.filterOwnedMechanics();

      expect(mechanics.length, 2);
      expect(mechanics.any((mechanic) => mechanic.id == 2002 && mechanic.name == 'Hand Management'), isTrue);
      expect(mechanics.any((mechanic) => mechanic.id == 2003 && mechanic.name == 'Campaign'), isTrue);
    });

    test('getExpansionsForGame() returns expansions for a specific game', () async {
      final game = _sampleGame(
        bggId: 900040,
        name: 'Game With Expansion',
        expansions: [_sampleExpansion(id: 999401, name: 'Expansion One')],
      );

      await repository.insertGameWithRelations(game);

      final expansions = await repository.getExpansionsForGame(900040);
      expect(expansions.length, 1);
      expect(expansions.first.id, 999401);
      expect(expansions.first.name, 'Expansion One');
    });
  });
}

BoardGame _sampleGame({
  int bggId = 1,
  String name = 'Sample Game',
  List<BoardGameCategory> categories = const [],
  List<BoardGameMechanic> mechanics = const [],
  List<BoardGameExpansion> expansions = const [],
}) {
  return BoardGame(
    bggId: bggId,
    name: name,
    categories: categories,
    mechanics: mechanics,
    expansions: expansions,
  );
}

Future<void> _buildSeededDatabaseFromSql({
  required DatabaseHelper helper,
  required String sqlPath,
}) async {
  final db = await helper.database;
  final sql = await File(sqlPath).readAsString();
  final statements = sql
      .split(';')
      .map((statement) => statement.trim())
      .where((statement) => statement.isNotEmpty);

  await db.transaction((txn) async {
    for (final statement in statements) {
      await txn.execute(statement);
    }
  });
}

BoardGameCriteria _sampleCriteria() {
  return const BoardGameCriteria();
}

BoardGameCategory _sampleCategory({int id = 1, String name = 'Sample Category'}) {
  return BoardGameCategory(id: id, name: name);
}

BoardGameMechanic _sampleMechanic({int id = 1, String name = 'Sample Mechanic'}) {
  return BoardGameMechanic(id: id, name: name);
}

BoardGameExpansion _sampleExpansion({int id = 1, String name = 'Sample Expansion'}) {
  return BoardGameExpansion(id: id, name: name);
}

List<BoardGame> _getExpectedGamesFromSeed() {
  return [
    BoardGame(
      bggId: 224517,
      name: 'Brass: Birmingham',
      yearPublished: 2018,
      isExpansion: false,
      minPlayers: 2,
      maxPlayers: 4,
      minPlaytime: 60,
      maxPlaytime: 120,
      age: 14,
      isFavorite: true,
      isOwned: true,
      timesPlayed: 5,
    ),
    BoardGame(
      bggId: 342942,
      name: 'Ark Nova',
      yearPublished: 2021,
      isExpansion: false,
      minPlayers: 1,
      maxPlayers: 4,
      minPlaytime: 90,
      maxPlaytime: 150,
      age: 14,
      isFavorite: false,
      isOwned: true,
      timesPlayed: 0,
    ),
    BoardGame(
      bggId: 161936,
      name: 'Pandemic Legacy: Season 1',
      yearPublished: 2015,
      isExpansion: false,
      minPlayers: 2,
      maxPlayers: 4,
      minPlaytime: 60,
      maxPlaytime: 60,
      age: 13,
      isFavorite: true,
      isOwned: false,
      timesPlayed: 2,
    ),
    BoardGame(
      bggId: 174430,
      name: 'Gloomhaven',
      yearPublished: 2017,
      isExpansion: false,
      minPlayers: 1,
      maxPlayers: 4,
      minPlaytime: 90,
      maxPlaytime: 180,
      age: 14,
      isFavorite: false,
      isOwned: true,
      timesPlayed: 10,
    ),
    BoardGame(
      bggId: 316554,
      name: 'Dune: Imperium',
      yearPublished: 2020,
      isExpansion: false,
      minPlayers: 1,
      maxPlayers: 4,
      minPlaytime: 60,
      maxPlaytime: 120,
      age: 13,
      isFavorite: true,
      isOwned: false,
      timesPlayed: 0,
    ),
    BoardGame(
      bggId: 295895,
      name: 'Distilled',
      yearPublished: 2023,
      isExpansion: false,
      minPlayers: 1,
      maxPlayers: 5,
      minPlaytime: 30,
      maxPlaytime: 150,
      age: 14,
      isFavorite: false,
      isOwned: true,
      timesPlayed: 1,
    ),
  ];
}
