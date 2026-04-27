import 'package:board_game_library/enums/game_sort_option.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';

class BoardGameCriteria {
  final int? minPlayers;
  final int? maxPlayers;
  final int? maxPlaytime;
  final int? age;
  final String? nameLike;
  final List<BoardGameCategory>? categories;
  final List<BoardGameMechanic>? mechanics;
  final bool? isFavorite;
  final bool? isExpansion;
  final bool? isUnplayed;
  final bool? isOwned;
  final GameSortOption sortOption;

  const BoardGameCriteria({
    this.minPlayers,
    this.maxPlayers,
    this.maxPlaytime,
    this.age,
    this.nameLike,
    this.categories = const [],
    this.mechanics = const [],
    this.isFavorite,
    this.isExpansion,
    this.isUnplayed,
    this.isOwned,
    this.sortOption = GameSortOption.nameAsc,
  });

  BoardGameCriteria copyWith({
    int? minPlayers,
    int? maxPlayers,
    int? maxPlaytime,
    int? age,
    String? nameLike,
    List<BoardGameCategory>? categories,
    List<BoardGameMechanic>? mechanics,
    bool? isFavorite,
    bool? isExpansion,
    bool? isUnplayed,
    bool? isOwned,
    GameSortOption? sortOption,
  }) {
    return BoardGameCriteria(
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      maxPlaytime: maxPlaytime ?? this.maxPlaytime,
      age: age ?? this.age,
      nameLike: nameLike ?? this.nameLike,
      categories: categories ?? this.categories,
      mechanics: mechanics ?? this.mechanics,
      isFavorite: isFavorite ?? this.isFavorite,
      isExpansion: isExpansion ?? this.isExpansion,
      isUnplayed: isUnplayed ?? this.isUnplayed,
      isOwned: isOwned ?? this.isOwned,
      sortOption: sortOption ?? this.sortOption,
    );
  }
  
}