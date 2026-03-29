import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:board_game_library/util/parsing.dart';

import '../models/board_game.dart';

Future<List<BoardGame>> loadBoardGamesFromJsonAsset({
	String assetPath = 'assets/available_games.json',
}) async {
	final raw = await rootBundle.loadString(assetPath);
	final decoded = jsonDecode(raw);

	if (decoded is List) {
		return decoded
				.whereType<Map<String, dynamic>>()
				.map(_boardGameFromJson)
				.toList(growable: false);
	}

	return const [];
}

BoardGame _boardGameFromJson(Map<String, dynamic> json) {
	return BoardGame(
		bggId: Parsing.toInt(json['bgg_id']) ?? 0,
		name: (json['name'] as String?)?.trim() ?? '',
		yearPublished: Parsing.toInt(json['year_published']),
		isExpansion: Parsing.toBool(json['is_expansion']),
	);
}
