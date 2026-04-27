import 'package:board_game_library/data/repository/games_repository.dart';
import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:board_game_library/state/games_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGamesRepository extends Mock implements GamesRepository {}

void main() {
  late _MockGamesRepository repo;
  late GamesNotifier notifier;

  final sampleGame = BoardGame(bggId: 1, name: 'Game A', isFavorite: false);

  setUpAll(() {
    registerFallbackValue(BoardGame(bggId: 0, name: 'fallback'));
    registerFallbackValue(const BoardGameCriteria());
  });

  setUp(() {
    repo = _MockGamesRepository();
    notifier = GamesNotifier(repo);
  });

  group('GamesNotifier basic loading', () {
    test('loadOwnedBaseGames updates filteredGames', () async {
      when(() => repo.getAllOwnedBaseGames()).thenAnswer((_) async => [sampleGame]);

      await notifier.loadOwnedBaseGames();

      expect(notifier.filteredGames.value.length, 1);
      expect(notifier.filteredGames.value.first.bggId, 1);
      verify(() => repo.getAllOwnedBaseGames()).called(1);
    });

    test('applyFilters stores criteria and updates filtered list', () async {
      const criteria = BoardGameCriteria(isOwned: true);
      when(() => repo.searchByCriteria(criteria)).thenAnswer((_) async => [sampleGame]);

      await notifier.applyFilters(criteria);

      expect(notifier.currentCriteria, criteria);
      expect(notifier.filteredGames.value.length, 1);
      verify(() => repo.searchByCriteria(criteria)).called(1);
    });

    test('clearFilters resets criteria and reloads owned games', () async {
      notifier.currentCriteria = const BoardGameCriteria(isOwned: true);
      when(() => repo.getAllOwnedBaseGames()).thenAnswer((_) async => [sampleGame]);

      await notifier.clearFilters();

      expect(notifier.currentCriteria, isNull);
      verify(() => repo.getAllOwnedBaseGames()).called(1);
    });
  });

  group('GamesNotifier mutation behavior', () {
    test('updateIsFavorite mutates matching item in filtered list', () async {
      final original = sampleGame.copyWith(isFavorite: false);
      (notifier.filteredGames as dynamic).value = [original];
      when(() => repo.updateIsFavorite(original, true)).thenAnswer((_) async {});

      await notifier.updateIsFavorite(original, true);

      expect(notifier.filteredGames.value.first.isFavorite, isTrue);
      verify(() => repo.updateIsFavorite(original, true)).called(1);
    });

    test('updateIsOwned mutates matching item in filtered list', () async {
      final original = sampleGame.copyWith(isOwned: false);
      (notifier.filteredGames as dynamic).value = [original];
      when(() => repo.updateIsOwned(original, true)).thenAnswer((_) async {});

      await notifier.updateIsOwned(original, true);

      expect(notifier.filteredGames.value.first.isOwned, isTrue);
      verify(() => repo.updateIsOwned(original, true)).called(1);
    });

    test('updateGame persists and replaces matching item', () async {
      final original = sampleGame.copyWith(name: 'Before');
      final updated = sampleGame.copyWith(name: 'After');
      (notifier.filteredGames as dynamic).value = [original];
      when(() => repo.persistGameWithRelations(updated, true)).thenAnswer((_) async {});

      await notifier.updateGame(updated);

      expect(notifier.filteredGames.value.first.name, 'After');
      verify(() => repo.persistGameWithRelations(updated, true)).called(1);
    });
  });

  group('GamesNotifier collection flow branches', () {
    test('addGameToCollection reloads owned games when criteria is null', () async {
      when(() => repo.addGameToCollection(any())).thenAnswer((_) async {});
      when(() => repo.getAllOwnedBaseGames()).thenAnswer((_) async => [sampleGame]);

      await notifier.addGameToCollection(sampleGame);

      verify(() => repo.addGameToCollection(sampleGame)).called(1);
      verify(() => repo.getAllOwnedBaseGames()).called(1);
    });

    test('addGameToCollection does not reapply filters when criteria isOwned is false', () async {
      notifier.currentCriteria = const BoardGameCriteria(isOwned: false);
      when(() => repo.addGameToCollection(any())).thenAnswer((_) async {});

      await notifier.addGameToCollection(sampleGame);

      verify(() => repo.addGameToCollection(sampleGame)).called(1);
      verifyNever(() => repo.searchByCriteria(any()));
      verifyNever(() => repo.getAllOwnedBaseGames());
    });

    test('addGameToCollection reapplies filters when current criteria includes owned games', () async {
      const criteria = BoardGameCriteria(isOwned: true);
      notifier.currentCriteria = criteria;
      when(() => repo.addGameToCollection(any())).thenAnswer((_) async {});
      when(() => repo.searchByCriteria(any())).thenAnswer((_) async => [sampleGame]);

      await notifier.addGameToCollection(sampleGame);

      verify(() => repo.addGameToCollection(sampleGame)).called(1);
      verify(() => repo.searchByCriteria(criteria)).called(1);
    });
  });

  group('GamesNotifier passthrough methods', () {
    test('ensureGameDetailsLoaded delegates to repository', () async {
      when(() => repo.ensureGameDetailsLoaded(any())).thenAnswer((_) async => sampleGame);

      final result = await notifier.ensureGameDetailsLoaded(1);

      expect(result, isNotNull);
      expect(result!.bggId, 1);
      verify(() => repo.ensureGameDetailsLoaded(1)).called(1);
    });

    test('loadOwnedCategories and loadOwnedMechanics update listenables', () async {
      when(() => repo.filterOwnedCategories()).thenAnswer(
        (_) async => [BoardGameCategory(id: 10, name: 'Category X')],
      );
      when(() => repo.filterOwnedMechanics()).thenAnswer(
        (_) async => [BoardGameMechanic(id: 20, name: 'Mechanic X')],
      );

      await notifier.loadOwnedCategories();
      await notifier.loadOwnedMechanics();

      expect(notifier.ownedCategories.value.length, 1);
      expect(notifier.ownedMechanics.value.length, 1);
    });

    test('paged fetch methods delegate to repository', () async {
      when(() => repo.getAllGamesPaged(0, 20, namePrefix: 'a')).thenAnswer(
        (_) async => [sampleGame],
      );
      when(
        () => repo.getOwnedGamesPaged(
          0,
          20,
          namePrefix: 'a',
          criteria: any(named: 'criteria'),
        ),
      ).thenAnswer((_) async => [sampleGame.copyWith(isOwned: true)]);

      final all = await notifier.getAllGamesPaged(0, 20, namePrefix: 'a');
      final owned = await notifier.getOwnedGamesPaged(
        0,
        20,
        namePrefix: 'a',
        criteria: const BoardGameCriteria(isOwned: true),
      );

      expect(all.length, 1);
      expect(owned.length, 1);
      expect(owned.first.isOwned, isTrue);
    });
  });
}
