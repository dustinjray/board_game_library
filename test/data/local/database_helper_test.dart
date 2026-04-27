import 'dart:io';

import 'package:board_game_library/config/database_factory_init.dart';
import 'package:board_game_library/data/dao/categories_dao.dart';
import 'package:board_game_library/data/dao/expansions_dao.dart';
import 'package:board_game_library/data/dao/games_dao.dart';
import 'package:board_game_library/data/dao/mechanics_dao.dart';
import 'package:board_game_library/data/dao/sql_categories_dao.dart';
import 'package:board_game_library/data/dao/sql_expansions_dao.dart';
import 'package:board_game_library/data/dao/sql_games_dao.dart';
import 'package:board_game_library/data/dao/sql_mechanics_dao.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/data/repository/sql_games_repository.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:board_game_library/services/board_game_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import '../../helpers/board_game_fixture_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;
  late SqlGamesRepository repository;
  late Directory tempDbDir;
  late String testDbPath;

  setUpAll(() async {
    await initializeDatabaseFactory();
    tempDbDir = await Directory.systemTemp.createTemp('board_game_library_test_db_');
    testDbPath = p.join(tempDbDir.path, 'board_games_test_database.db');
    DatabaseHelper.setDatabasePathOverrideForTesting(testDbPath);
  });

  setUp(() async {
    helper = DatabaseHelper();
    await helper.close();
    final dbFile = File(testDbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    final GamesDAO gamesDAO = SqlGamesDAO(helper);
    final CategoriesDAO categoriesDAO = SqlCategoriesDAO(helper);
    final MechanicsDAO mechanicsDAO = SqlMechanicsDAO(helper);
    final ExpansionsDAO expansionsDAO = SqlExpansionsDAO(helper);

    repository = SqlGamesRepository(
      helper,
      gamesDAO,
      categoriesDAO,
      mechanicsDAO,
      expansionsDAO,
      _NoopBoardGameService(),
    );
  });

  tearDownAll(() async {
    await helper.close();
    DatabaseHelper.setDatabasePathOverrideForTesting(null);
    if (await tempDbDir.exists()) {
      await tempDbDir.delete(recursive: true);
    }
  });

  test('updates game 295895 from XML, syncs categories, and removes relations on delete', () async {
    final gameFromXml = await loadBoardGameFromFixture('lib/resources/BoardGameResponse.xml');

    expect(gameFromXml.bggId, 295895);

    await repository.insertGameWithRelations(gameFromXml);

    final inserted = await repository.getGameById(295895);
    expect(inserted, isNotNull);
    expect(inserted!.categories, isNotEmpty);

    const testCategoryId = 999001;
    const testCategoryName = 'Unit Test Category';
    final addedCategory = BoardGameCategory(id: testCategoryId, name: testCategoryName);

    final withAddedCategory = gameFromXml.copyWith(
      name: '${gameFromXml.name} (Updated)',
      categories: [...gameFromXml.categories, addedCategory],
    );

    await repository.updateGameWithRelations(withAddedCategory);

    final afterAdd = await repository.getGameById(295895);
    expect(afterAdd, isNotNull);
    expect(afterAdd!.name, '${gameFromXml.name} (Updated)');
    expect(afterAdd.categories.any((c) => c.id == testCategoryId), isTrue);

    final withRemovedCategory = withAddedCategory.copyWith(
      categories: gameFromXml.categories,
    );

    await repository.updateGameWithRelations(withRemovedCategory);

    final afterRemove = await repository.getGameById(295895);
    expect(afterRemove, isNotNull);
    expect(afterRemove!.categories.any((c) => c.id == testCategoryId), isFalse);

    await repository.deleteGame(withRemovedCategory);

    final deletedGame = await repository.getGameById(295895);
    expect(deletedGame, isNull);

    final db = await helper.database;
    final categoryLinks = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM board_game_categories WHERE board_game_id = ?',
      [295895],
    );
    final mechanicLinks = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM board_game_mechanics WHERE board_game_id = ?',
      [295895],
    );
    final expansionLinks = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM board_game_expansions WHERE board_game_id = ?',
      [295895],
    );

    expect(categoryLinks.first['count'], 0);
    expect(mechanicLinks.first['count'], 0);
    expect(expansionLinks.first['count'], 0);
  });

  test('syncs mechanics and expansions on update with add and remove operations', () async {
    final gameFromXml = await loadBoardGameFromFixture('lib/resources/BoardGameResponse.xml');

    expect(gameFromXml.bggId, 295895);
    expect(gameFromXml.mechanics, isNotEmpty);
    expect(gameFromXml.expansions, isNotEmpty);

    await repository.insertGameWithRelations(gameFromXml);

    final removedOriginalMechanicId = gameFromXml.mechanics.first.id;
    final removedOriginalExpansionId = gameFromXml.expansions.first.id;

    const addedMechanicId = 999101;
    const addedExpansionId = 999201;

    final addedMechanic = BoardGameMechanic(id: addedMechanicId, name: 'Unit Test Mechanic');
    final addedExpansion = BoardGameExpansion(id: addedExpansionId, name: 'Unit Test Expansion');

    final updatedGame = gameFromXml.copyWith(
      mechanics: [...gameFromXml.mechanics.skip(1), addedMechanic],
      expansions: [...gameFromXml.expansions.skip(1), addedExpansion],
    );

    await repository.updateGameWithRelations(updatedGame);

    final afterFirstUpdate = await repository.getGameById(295895);
    expect(afterFirstUpdate, isNotNull);
    expect(afterFirstUpdate!.mechanics.any((mechanic) => mechanic.id == addedMechanicId), isTrue);
    expect(afterFirstUpdate.mechanics.any((mechanic) => mechanic.id == removedOriginalMechanicId), isFalse);
    expect(afterFirstUpdate.expansions.any((expansion) => expansion.id == addedExpansionId), isTrue);
    expect(afterFirstUpdate.expansions.any((expansion) => expansion.id == removedOriginalExpansionId), isFalse);

    final restoredGame = updatedGame.copyWith(
      mechanics: gameFromXml.mechanics,
      expansions: gameFromXml.expansions,
    );

    await repository.updateGameWithRelations(restoredGame);

    final afterSecondUpdate = await repository.getGameById(295895);
    expect(afterSecondUpdate, isNotNull);
    expect(afterSecondUpdate!.mechanics.any((mechanic) => mechanic.id == addedMechanicId), isFalse);
    expect(afterSecondUpdate.mechanics.any((mechanic) => mechanic.id == removedOriginalMechanicId), isTrue);
    expect(afterSecondUpdate.expansions.any((expansion) => expansion.id == addedExpansionId), isFalse);
    expect(afterSecondUpdate.expansions.any((expansion) => expansion.id == removedOriginalExpansionId), isTrue);
  });
}

class _NoopBoardGameService extends BoardGameService {}
