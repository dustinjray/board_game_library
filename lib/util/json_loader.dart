import 'dart:convert';

import 'package:flutter/services.dart';

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
		bggId: _toInt(json['bgg_id']) ?? 0,
		name: (json['name'] as String?)?.trim() ?? '',
		yearPublished: _toInt(json['year_published']),
		isExpansion: _toBool(json['is_expansion']),
	);
}

int? _toInt(dynamic value) {
	if (value == null) {
		return null;
	}
	if (value is int) {
		return value;
	}
	if (value is num) {
		return value.toInt();
	}
	if (value is String) {
		return int.tryParse(value.trim());
	}
	return null;
}

bool _toBool(dynamic value) {
	if (value == null) {
		return false;
	}
	if (value is bool) {
		return value;
	}
	if (value is num) {
		return value != 0;
	}
	if (value is String) {
		final normalized = value.trim().toLowerCase();
		return normalized == '1' || normalized == 'true' || normalized == 'yes';
	}
	return false;
}
