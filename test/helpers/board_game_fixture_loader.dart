import 'dart:io';

import 'package:board_game_library/models/board_game.dart';
import 'package:xml/xml.dart' as xml;

Future<BoardGame> loadBoardGameFromFixture(String fixturePath) async {
  final xmlString = await File(fixturePath).readAsString();
  final xmlDoc = xml.XmlDocument.parse(xmlString);
  final boardgameElement = xmlDoc.findAllElements('boardgame').first;
  return BoardGame.fromXML(boardgameElement.toXmlString());
}
