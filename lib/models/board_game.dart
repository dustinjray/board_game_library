import 'package:xml/xml.dart' as xml;
import 'package:board_game_library/util/parsing.dart';

import 'board_game_category.dart';
import 'board_game_expansion.dart';
import 'board_game_mechanic.dart';

class BoardGame {
  final int bggId;
  final String name;
  final int? yearPublished;
  final bool isExpansion;
  final int? minPlayers;
  final int? maxPlayers;
  final int? minPlaytime;
  final int? maxPlaytime;
  final int? age;
  final String? description;
  final String? thumbnail;
  final String? image;
  final List<BoardGameCategory> categories;
  final List<BoardGameExpansion> expansions;
  final List<BoardGameMechanic> mechanics;
  final bool isFavorite;
  final int timesPlayed;
  final bool isOwned;
  final bool detailsFetched;

  // bool get hasFetchedDetails {
  //   return minPlayers != null ||
  //       maxPlayers != null ||
  //       minPlaytime != null ||
  //       maxPlaytime != null ||
  //       age != null ||
  //       (description?.trim().isNotEmpty ?? false) ||
  //       (thumbnail?.trim().isNotEmpty ?? false) ||
  //       (image?.trim().isNotEmpty ?? false) ||
  //       categories.isNotEmpty ||
  //       mechanics.isNotEmpty ||
  //       expansions.isNotEmpty;
  // }

  bool get needsDetailsFetch => !detailsFetched;

  BoardGame({
    required this.bggId,
    required this.name,
    this.yearPublished,
    this.isExpansion = false,
    this.minPlayers,
    this.maxPlayers,
    this.minPlaytime,
    this.maxPlaytime,
    this.age,
    this.description,
    this.thumbnail,
    this.image,
    this.categories = const [],
    this.expansions = const [],
    this.mechanics = const [],
    this.isFavorite = false,
    this.timesPlayed = 0,
    this.isOwned = false,
    this.detailsFetched = false,
  });

  /// Creates a BoardGame from an XML string containing a boardgames response
  factory BoardGame.fromXML(String xmlString) {
    final document = xml.XmlDocument.parse(xmlString);
    final boardgameElement = document.findElements('boardgame').first;

    return BoardGame.fromXmlElement(boardgameElement);
  }

  factory BoardGame.fromXmlElement(xml.XmlElement boardgameElement) {
    // Extract ID from objectid attribute
    final bggId = Parsing.toInt(boardgameElement.getAttribute('objectid')) ?? 0;

    // Extract simple text elements
    final yearPublishedElement =
      boardgameElement.findElements('yearpublished').firstOrNull?.innerText;
    final yearPublished = yearPublishedElement != null
      ? int.tryParse(yearPublishedElement)
      : null;

    final minPlayersElement =
        boardgameElement.findElements('minplayers').firstOrNull?.innerText;
    final minPlayers =
      minPlayersElement != null ? Parsing.toInt(minPlayersElement) : null;

    final maxPlayersElement =
        boardgameElement.findElements('maxplayers').firstOrNull?.innerText;
    final maxPlayers =
      maxPlayersElement != null ? Parsing.toInt(maxPlayersElement) : null;

    final minPlaytimeElement =
        boardgameElement.findElements('minplaytime').firstOrNull?.innerText;
    final minPlaytime =
      minPlaytimeElement != null ? Parsing.toInt(minPlaytimeElement) : null;

    final maxPlaytimeElement =
        boardgameElement.findElements('maxplaytime').firstOrNull?.innerText;
    final maxPlaytime =
      maxPlaytimeElement != null ? Parsing.toInt(maxPlaytimeElement) : null;

    final ageElement = boardgameElement.findElements('age').firstOrNull?.innerText;
    final age = ageElement != null ? Parsing.toInt(ageElement) : null;

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
              id: Parsing.toInt(element.getAttribute('objectid')) ?? 0,
              name: element.innerText,
            ))
        .toList();

    // Extract expansions
    final boardGameExpansionElements = boardgameElement
      .findElements('boardgameexpansion')
      .toList();

    final isExpansion = boardGameExpansionElements
      .any((element) => element.getAttribute('inbound') == 'true');

    final expansions = boardgameElement
      .findElements('boardgameexpansion')
      .where((element) => element.getAttribute('inbound') != 'true')
        .map((element) => BoardGameExpansion(
          id: Parsing.toInt(element.getAttribute('objectid')) ?? 0,
              name: element.innerText,
            ))
        .toList();

    // Extract mechanics
    final mechanics = boardgameElement
        .findElements('boardgamemechanic')
        .map((element) => BoardGameMechanic(
              id: Parsing.toInt(element.getAttribute('objectid')) ?? 0,
              name: element.innerText,
            ))
        .toList();

    return BoardGame(
      bggId: bggId,
      name: name,
      yearPublished: yearPublished,
      isExpansion: isExpansion,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      minPlaytime: minPlaytime,
      maxPlaytime: maxPlaytime,
      age: age,
      description: description,
      thumbnail: thumbnail,
      image: image,
      categories: categories,
      expansions: expansions,
      mechanics: mechanics,
      isFavorite: false,
      isOwned: false,
      timesPlayed: 0,
      detailsFetched: true,
    );
  }

  /// Converts BoardGame to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'bgg_id': bggId,
      'name': name,
      'year_published': yearPublished,
      'is_expansion': isExpansion ? 1 : 0,
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'min_playtime': minPlaytime,
      'max_playtime': maxPlaytime,
      'age': age,
      'description': description,
      'thumbnail': thumbnail,
      'image': image,
      'is_favorite': isFavorite ? 1 : 0,
      'is_owned': isOwned ? 1 : 0,
      'times_played': timesPlayed,
      'details_fetched': detailsFetched ? 1 : 0,
    };
  }

  /// Creates a BoardGame from a database Map
  factory BoardGame.fromMap(Map<String, dynamic> map) {
    final dynamic yearPublishedValue = map['year_published'];
    final dynamic bggIdValue = map['bgg_id'];
    final dynamic isExpansionValue = map['is_expansion'];

    return BoardGame(
      bggId: Parsing.toInt(bggIdValue) ?? 0,
      name: map['name'] as String,
      yearPublished: Parsing.toInt(yearPublishedValue),
      isExpansion: Parsing.toBool(isExpansionValue),
      minPlayers: map['min_players'] as int?,
      maxPlayers: map['max_players'] as int?,
      minPlaytime: map['min_playtime'] as int?,
      maxPlaytime: map['max_playtime'] as int?,
      age: map['age'] as int?,
      description: map['description'] as String?,
      thumbnail: map['thumbnail'] as String?,
      image: map['image'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      isOwned: (map['is_owned'] as int?) == 1,
      timesPlayed: (map['times_played'] as int?) ?? 0,
      detailsFetched: (map['details_fetched'] as int?) == 1,
    );
  }

  BoardGame copyWith({
    int? bggId,
    String? name,
    int? yearPublished,
    bool? isExpansion,
    int? minPlayers,
    int? maxPlayers,
    int? minPlaytime,
    int? maxPlaytime,
    int? age,
    String? description,
    String? thumbnail,
    String? image,
    List<BoardGameCategory>? categories,
    List<BoardGameExpansion>? expansions,
    List<BoardGameMechanic>? mechanics,
    bool? isFavorite,
    int? timesPlayed,
    bool? isOwned,
    bool? detailsFetched,
  }) {
    return BoardGame(
      bggId: bggId ?? this.bggId,
      name: name ?? this.name,
      yearPublished: yearPublished ?? this.yearPublished,
      isExpansion: isExpansion ?? this.isExpansion,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlaytime: minPlaytime ?? this.minPlaytime,
      maxPlaytime: maxPlaytime ?? this.maxPlaytime,
      age: age ?? this.age,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      image: image ?? this.image,
      categories: categories ?? this.categories,
      expansions: expansions ?? this.expansions,
      mechanics: mechanics ?? this.mechanics,
      isFavorite: isFavorite ?? this.isFavorite,
      timesPlayed: timesPlayed ?? this.timesPlayed,
      isOwned: isOwned ?? this.isOwned,
      detailsFetched: detailsFetched ?? this.detailsFetched,
    );
  }
}
