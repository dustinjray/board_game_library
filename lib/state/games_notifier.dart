import 'dart:core';

import 'package:board_game_library/data/repository/games_repository.dart';
import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_criteria.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:flutter/foundation.dart';

class GamesNotifier extends ChangeNotifier {
  final GamesRepository _repo;
  BoardGameCriteria? currentCriteria;
  ValueListenable<List<BoardGame>> filteredGames = ValueNotifier([]);
  ValueListenable<List<BoardGameMechanic>> ownedMechanics = ValueNotifier([]);
  ValueListenable<List<BoardGameCategory>> ownedCategories = ValueNotifier([]);

  GamesNotifier(this._repo);

  // Need to add a method to the repo to only get the minimal data for the games in the database.

  Future<void> loadOwnedBaseGames() async {
    final games = await _repo.getAllOwnedBaseGames();
    (filteredGames as ValueNotifier<List<BoardGame>>).value = games;
    notifyListeners();
  }

  Future<void> applyFilters(BoardGameCriteria criteria) async {
    currentCriteria = criteria;
    final games = await _repo.searchByCriteria(criteria);
    (filteredGames as ValueNotifier<List<BoardGame>>).value = games;
    notifyListeners();
  }

  Future<void> clearFilters() async {
    currentCriteria = null;
    await loadOwnedBaseGames();
  }

  Future<void> loadOwnedMechanics() async {
    final mechanics = await _repo.filterOwnedMechanics();
    (ownedMechanics as ValueNotifier<List<BoardGameMechanic>>).value =
        mechanics;
    notifyListeners();
  }

  Future<void> loadOwnedCategories() async {
    final categories = await _repo.filterOwnedCategories();
    (ownedCategories as ValueNotifier<List<BoardGameCategory>>).value =
        categories;
    notifyListeners();
  }

  Future<BoardGame?> getGameById(int id) async {
    return await _repo.getGameById(id);
  }

  Future<BoardGame?> ensureGameDetailsLoaded(int id) async {
    return await _repo.ensureGameDetailsLoaded(id);
  }

  Future<void> addGameToCollection(BoardGame game) async {
    await _repo.addGameToCollection(game);

    if (currentCriteria == null) {
      await loadOwnedBaseGames();
      return;
    }

    if (currentCriteria!.isOwned == false) {
      return;
    }

    await applyFilters(currentCriteria!);
  }

  Future<void> updateIsFavorite(BoardGame game, bool isFavorite) async {
    await _repo.updateIsFavorite(game, isFavorite);
    // If the game is in the current filtered list, update it there as well
    final currentList = filteredGames.value;
    final index = currentList.indexWhere((g) => g.bggId == game.bggId);
    if (index != -1) {
      final updatedGame = game.copyWith(isFavorite: isFavorite);
      currentList[index] = updatedGame;
      (filteredGames as ValueNotifier<List<BoardGame>>).value = List.from(
        currentList,
      );
      notifyListeners();
    }
  }

  Future<void> updateIsOwned(BoardGame game, bool isOwned) async {
    await _repo.updateIsOwned(game, isOwned);
    // If the game is in the current filtered list, update it there as well
    final currentList = filteredGames.value;
    final index = currentList.indexWhere((g) => g.bggId == game.bggId);
    if (index != -1) {
      final updatedGame = game.copyWith(isOwned: isOwned);
      currentList[index] = updatedGame;
      (filteredGames as ValueNotifier<List<BoardGame>>).value = List.from(
        currentList,
      );
      notifyListeners();
    }
  }

  Future<void> updateGame(BoardGame game) async {
    await _repo.persistGameWithRelations(game, true);
    // If the game is in the current filtered list, update it there as well
    final currentList = filteredGames.value;
    final index = currentList.indexWhere((g) => g.bggId == game.bggId);
    if (index != -1) {
      currentList[index] = game;
      (filteredGames as ValueNotifier<List<BoardGame>>).value = List.from(
        currentList,
      );
      notifyListeners();
    }
  }

  Future<List<BoardGame>> getAllGamesPaged(
    int page,
    int pageSize, {
    String? namePrefix,
  }) async {
    return await _repo.getAllGamesPaged(page, pageSize, namePrefix: namePrefix);
  }

  Future<List<BoardGame>> getOwnedGamesPaged(
    int page,
    int pageSize, {
    String? namePrefix,
    BoardGameCriteria? criteria,
  }) async {
    return await _repo.getOwnedGamesPaged(
      page,
      pageSize,
      namePrefix: namePrefix,
      criteria: criteria,
    );
  }
}
