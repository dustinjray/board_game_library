import 'package:board_game_library/services/board_game_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('BoardGameService.fetchBoardGameDetails', () {
    test('returns parsed board game for HTTP 200 response', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/boardgame/123');
        return http.Response('''
<boardgames>
  <boardgame objectid="123">
    <name primary="true">Service Game</name>
    <yearpublished>2021</yearpublished>
    <boardgamecategory objectid="100">Category A</boardgamecategory>
  </boardgame>
</boardgames>
''', 200);
      });

      final service = BoardGameService(
        client: client,
        baseUrl: 'https://example.test',
      );

      final game = await service.fetchBoardGameDetails(123);

      expect(game.bggId, 123);
      expect(game.name, 'Service Game');
      expect(game.yearPublished, 2021);
      expect(game.categories.length, 1);
      expect(game.detailsFetched, isTrue);
    });

    test('throws for non-200 responses', () async {
      final client = MockClient((request) async => http.Response('oops', 500));
      final service = BoardGameService(
        client: client,
        baseUrl: 'https://example.test',
      );

      await expectLater(
        () => service.fetchBoardGameDetails(1),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('HTTP 500'),
          ),
        ),
      );
    });

    test('throws when boardgames root is missing', () async {
      final client = MockClient(
        (request) async => http.Response('<bad></bad>', 200),
      );
      final service = BoardGameService(
        client: client,
        baseUrl: 'https://example.test',
      );

      await expectLater(
        () => service.fetchBoardGameDetails(1),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Board games element not found'),
          ),
        ),
      );
    });

    test('throws when boardgame child is missing', () async {
      final client = MockClient(
        (request) async => http.Response('<boardgames></boardgames>', 200),
      );
      final service = BoardGameService(
        client: client,
        baseUrl: 'https://example.test',
      );

      await expectLater(
        () => service.fetchBoardGameDetails(1),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Board game element not found'),
          ),
        ),
      );
    });
  });
}
