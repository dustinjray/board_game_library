import 'package:board_game_library/models/board_game.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class BoardGameService {
  final String baseUrl;
  final http.Client _client;

  BoardGameService({
    http.Client? client,
    this.baseUrl = "https://bg-library-api-630738732167.us-east1.run.app",
  }) : _client = client ?? http.Client();

  Future<BoardGame> fetchBoardGameDetails(int id) async {
    final url = Uri.parse('$baseUrl/boardgame/$id');
    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch board game details for id $id: HTTP ${response.statusCode}',
      );
    }

    final data = XmlDocument.parse(response.body);
    final boardGamesElement = data.getElement('boardgames');
    if (boardGamesElement == null) {
      throw Exception('Board games element not found in response');
    }

    final boardGameElement = boardGamesElement.getElement('boardgame');
    if (boardGameElement == null) {
      throw Exception('Board game element not found in response');
    }

    return BoardGame.fromXmlElement(boardGameElement);
  }
}