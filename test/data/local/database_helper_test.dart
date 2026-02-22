import 'dart:io';

import 'package:board_game_library/config/database_factory_init.dart';
import 'package:board_game_library/data/local/database_helper.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import '../../helpers/board_game_fixture_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;
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

    await helper.insertBoardGameWithRelations(gameFromXml);

    final inserted = await helper.getBoardGameWithRelationsById(295895);
    expect(inserted, isNotNull);
    expect(inserted!.categories, isNotEmpty);

    const testCategoryId = 999001;
    const testCategoryName = 'Unit Test Category';
    final addedCategory = BoardGameCategory(id: testCategoryId, name: testCategoryName);

    final withAddedCategory = gameFromXml.copyWith(
      name: '${gameFromXml.name} (Updated)',
      categories: [...gameFromXml.categories, addedCategory],
    );

    await helper.updateBoardGameWithRelations(withAddedCategory);

    final afterAdd = await helper.getBoardGameWithRelationsById(295895);
    expect(afterAdd, isNotNull);
    expect(afterAdd!.name, '${gameFromXml.name} (Updated)');
    expect(afterAdd.categories.any((c) => c.id == testCategoryId), isTrue);

    final withRemovedCategory = withAddedCategory.copyWith(
      categories: gameFromXml.categories,
    );

    await helper.updateBoardGameWithRelations(withRemovedCategory);

    final afterRemove = await helper.getBoardGameWithRelationsById(295895);
    expect(afterRemove, isNotNull);
    expect(afterRemove!.categories.any((c) => c.id == testCategoryId), isFalse);

    await helper.deleteBoardGame(295895);

    final deletedGame = await helper.getBoardGameById(295895);
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

    await helper.insertBoardGameWithRelations(gameFromXml);

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

    await helper.updateBoardGameWithRelations(updatedGame);

    final afterFirstUpdate = await helper.getBoardGameWithRelationsById(295895);
    expect(afterFirstUpdate, isNotNull);
    expect(afterFirstUpdate!.mechanics.any((mechanic) => mechanic.id == addedMechanicId), isTrue);
    expect(afterFirstUpdate.mechanics.any((mechanic) => mechanic.id == removedOriginalMechanicId), isFalse);
    expect(afterFirstUpdate.expansions.any((expansion) => expansion.id == addedExpansionId), isTrue);
    expect(afterFirstUpdate.expansions.any((expansion) => expansion.id == removedOriginalExpansionId), isFalse);

    final restoredGame = updatedGame.copyWith(
      mechanics: gameFromXml.mechanics,
      expansions: gameFromXml.expansions,
    );

    await helper.updateBoardGameWithRelations(restoredGame);

    final afterSecondUpdate = await helper.getBoardGameWithRelationsById(295895);
    expect(afterSecondUpdate, isNotNull);
    expect(afterSecondUpdate!.mechanics.any((mechanic) => mechanic.id == addedMechanicId), isFalse);
    expect(afterSecondUpdate.mechanics.any((mechanic) => mechanic.id == removedOriginalMechanicId), isTrue);
    expect(afterSecondUpdate.expansions.any((expansion) => expansion.id == addedExpansionId), isFalse);
    expect(afterSecondUpdate.expansions.any((expansion) => expansion.id == removedOriginalExpansionId), isTrue);
  });
}
