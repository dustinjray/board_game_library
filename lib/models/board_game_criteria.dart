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
  });
  
}