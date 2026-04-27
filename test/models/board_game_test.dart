import 'package:board_game_library/models/board_game.dart';
import 'package:board_game_library/models/board_game_category.dart';
import 'package:board_game_library/models/board_game_expansion.dart';
import 'package:board_game_library/models/board_game_mechanic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart' as xml;

void main() {
  group('BoardGame.fromMap', () {
    test('parses coercible values and defaults correctly', () {
      final map = <String, dynamic>{
        'bgg_id': '100',
        'name': 'Test Game',
        'year_published': '2020',
        'is_expansion': 0,
        'min_players': 1,
        'max_players': 4,
        'min_playtime': 30,
        'max_playtime': 60,
        'age': 12,
        'description': 'desc',
        'thumbnail': 'thumb',
        'image': 'image',
        'is_favorite': 1,
        'is_owned': 0,
        'times_played': 3,
        'details_fetched': 1,
      };

      final game = BoardGame.fromMap(map);

      expect(game.bggId, 100);
      expect(game.name, 'Test Game');
      expect(game.yearPublished, 2020);
      expect(game.isExpansion, isFalse);
      expect(game.isFavorite, isTrue);
      expect(game.isOwned, isFalse);
      expect(game.timesPlayed, 3);
      expect(game.detailsFetched, isTrue);
    });
  });

  group('BoardGame.toMap/fromMap roundtrip', () {
    test('preserves stored scalar fields', () {
      final original = BoardGame(
        bggId: 200,
        name: 'Roundtrip',
        yearPublished: 2021,
        isExpansion: true,
        minPlayers: 2,
        maxPlayers: 5,
        minPlaytime: 40,
        maxPlaytime: 90,
        age: 14,
        description: 'hello',
        thumbnail: 'thumb',
        image: 'img',
        categories: [BoardGameCategory(id: 1, name: 'Category A')],
        mechanics: [BoardGameMechanic(id: 2, name: 'Mechanic A')],
        expansions: [BoardGameExpansion(id: 3, name: 'Expansion A')],
        isFavorite: true,
        timesPlayed: 11,
        isOwned: true,
        detailsFetched: true,
      );

      final restored = BoardGame.fromMap(original.toMap());

      expect(restored.bggId, original.bggId);
      expect(restored.name, original.name);
      expect(restored.yearPublished, original.yearPublished);
      expect(restored.isExpansion, original.isExpansion);
      expect(restored.minPlayers, original.minPlayers);
      expect(restored.maxPlayers, original.maxPlayers);
      expect(restored.minPlaytime, original.minPlaytime);
      expect(restored.maxPlaytime, original.maxPlaytime);
      expect(restored.age, original.age);
      expect(restored.description, original.description);
      expect(restored.thumbnail, original.thumbnail);
      expect(restored.image, original.image);
      expect(restored.isFavorite, original.isFavorite);
      expect(restored.isOwned, original.isOwned);
      expect(restored.timesPlayed, original.timesPlayed);
      expect(restored.detailsFetched, original.detailsFetched);
      expect(restored.categories, isEmpty);
      expect(restored.mechanics, isEmpty);
      expect(restored.expansions, isEmpty);
    });
  });

  group('BoardGame.fromXmlElement', () {
    test('uses primary name and handles inbound expansion flags', () {
      final doc = xml.XmlDocument.parse('''
<boardgame objectid="300">
  <yearpublished>2022</yearpublished>
  <name sortindex="1">Fallback Name</name>
  <name primary="true" sortindex="1">Primary Name</name>
  <boardgamecategory objectid="10">Category X</boardgamecategory>
  <boardgamemechanic objectid="20">Mechanic X</boardgamemechanic>
  <boardgameexpansion objectid="30" inbound="true">Base Game</boardgameexpansion>
  <boardgameexpansion objectid="31">Expansion A</boardgameexpansion>
</boardgame>
''');

      final game = BoardGame.fromXmlElement(doc.rootElement);

      expect(game.bggId, 300);
      expect(game.name, 'Primary Name');
      expect(game.isExpansion, isTrue);
      expect(game.expansions.length, 1);
      expect(game.expansions.first.id, 31);
      expect(game.categories.length, 1);
      expect(game.mechanics.length, 1);
      expect(game.detailsFetched, isTrue);
    });

    test('falls back to first name when no primary flag exists', () {
      final doc = xml.XmlDocument.parse('''
<boardgame objectid="301">
  <name>Only Name</name>
</boardgame>
''');

      final game = BoardGame.fromXmlElement(doc.rootElement);
      expect(game.name, 'Only Name');
      expect(game.bggId, 301);
    });
  });
}
