import 'package:xml/xml.dart' as xml;

import 'board_game_category.dart';
import 'board_game_expansion.dart';
import 'board_game_mechanic.dart';

class BoardGame {
  final int id;
  final String name;
  final String? yearpublished;
  final bool isExpansion;
  final int? minplayers;
  final int? maxplayers;
  final int? minplaytime;
  final int? maxplaytime;
  final int? age;
  final String? description;
  final String? thumbnail;
  final String? image;
  final List<BoardGameCategory> categories;
  final List<BoardGameExpansion> expansions;
  final List<BoardGameMechanic> mechanics;

  BoardGame({
    required this.id,
    required this.name,
    this.yearpublished,
    this.isExpansion = false,
    this.minplayers,
    this.maxplayers,
    this.minplaytime,
    this.maxplaytime,
    this.age,
    this.description,
    this.thumbnail,
    this.image,
    this.categories = const [],
    this.expansions = const [],
    this.mechanics = const [],
  });

  /// Creates a BoardGame from an XML string containing a boardgames response
  factory BoardGame.fromXML(String xmlString) {
    final document = xml.XmlDocument.parse(xmlString);
    final boardgameElement = document.findElements('boardgame').first;

    // Extract ID from objectid attribute
    final id = int.parse(boardgameElement.getAttribute('objectid')!);

    // Extract simple text elements
    final yearpublished =
        boardgameElement.findElements('yearpublished').firstOrNull?.innerText;

    final minplayersElement =
        boardgameElement.findElements('minplayers').firstOrNull?.innerText;
    final minplayers =
        minplayersElement != null ? int.parse(minplayersElement) : null;

    final maxplayersElement =
        boardgameElement.findElements('maxplayers').firstOrNull?.innerText;
    final maxplayers =
        maxplayersElement != null ? int.parse(maxplayersElement) : null;

    final minplaytimeElement =
        boardgameElement.findElements('minplaytime').firstOrNull?.innerText;
    final minplaytime =
        minplaytimeElement != null ? int.parse(minplaytimeElement) : null;

    final maxplaytimeElement =
        boardgameElement.findElements('maxplaytime').firstOrNull?.innerText;
    final maxplaytime =
        maxplaytimeElement != null ? int.parse(maxplaytimeElement) : null;

    final ageElement = boardgameElement.findElements('age').firstOrNull?.innerText;
    final age = ageElement != null ? int.parse(ageElement) : null;

    // Extract name with primary="true" attribute
    final name = boardgameElement
        .findElements('name')
        .firstWhere(
          (element) => element.getAttribute('primary') == 'true',
          orElse: () => boardgameElement.findElements('name').first,
        )
        .innerText;

    // Extract description, thumbnail, and image
    final description =
        boardgameElement.findElements('description').firstOrNull?.innerText;
    final thumbnail =
        boardgameElement.findElements('thumbnail').firstOrNull?.innerText;
    final image = boardgameElement.findElements('image').firstOrNull?.innerText;

    // Extract categories
    final categories = boardgameElement
        .findElements('boardgamecategory')
        .map((element) => BoardGameCategory(
              id: int.parse(element.getAttribute('objectid')!),
              name: element.innerText,
            ))
        .toList();

    // Extract expansions
    final expansions = boardgameElement
        .findElements('boardgameexpansion')
        .map((element) => BoardGameExpansion(
              id: int.parse(element.getAttribute('objectid')!),
              name: element.innerText,
            ))
        .toList();

    // Extract mechanics
    final mechanics = boardgameElement
        .findElements('boardgamemechanic')
        .map((element) => BoardGameMechanic(
              id: int.parse(element.getAttribute('objectid')!),
              name: element.innerText,
            ))
        .toList();

    return BoardGame(
      id: id,
      name: name,
      yearpublished: yearpublished,
      isExpansion: false,
      minplayers: minplayers,
      maxplayers: maxplayers,
      minplaytime: minplaytime,
      maxplaytime: maxplaytime,
      age: age,
      description: description,
      thumbnail: thumbnail,
      image: image,
      categories: categories,
      expansions: expansions,
      mechanics: mechanics,
    );
  }

  /// Converts BoardGame to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'year_published': yearpublished,
      'is_expansion': isExpansion ? 1 : 0,
      'min_players': minplayers,
      'max_players': maxplayers,
      'min_playtime': minplaytime,
      'max_playtime': maxplaytime,
      'age': age,
      'description': description,
      'thumbnail': thumbnail,
      'image': image,
    };
  }

  /// Creates a BoardGame from a database Map
  factory BoardGame.fromMap(Map<String, dynamic> map) {
    return BoardGame(
      id: map['id'] as int,
      name: map['name'] as String,
      yearpublished: map['year_published'] as String?,
      isExpansion: (map['is_expansion'] as int?) == 1,
      minplayers: map['min_players'] as int?,
      maxplayers: map['max_players'] as int?,
      minplaytime: map['min_playtime'] as int?,
      maxplaytime: map['max_playtime'] as int?,
      age: map['age'] as int?,
      description: map['description'] as String?,
      thumbnail: map['thumbnail'] as String?,
      image: map['image'] as String?,
    );
  }
}
