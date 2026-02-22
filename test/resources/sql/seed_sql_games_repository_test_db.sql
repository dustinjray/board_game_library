DELETE FROM board_game_categories;
DELETE FROM board_game_mechanics;
DELETE FROM board_game_expansions;
DELETE FROM categories;
DELETE FROM mechanics;
DELETE FROM expansions;
DELETE FROM board_games;

INSERT INTO board_games (
	bgg_id, name, year_published, is_expansion,
	min_players, max_players, min_playtime, max_playtime, age,
	is_favorite, is_owned, times_played
) VALUES (224517, 'Brass: Birmingham', 2018, 0, 2, 4, 60, 120, 14, 1, 1, 5);

INSERT INTO board_games (
	bgg_id, name, year_published, is_expansion,
	min_players, max_players, min_playtime, max_playtime, age,
	is_favorite, is_owned, times_played
) VALUES (342942, 'Ark Nova', 2021, 0, 1, 4, 90, 150, 14, 0, 1, 0);

INSERT INTO board_games (
	bgg_id, name, year_published, is_expansion,
	min_players, max_players, min_playtime, max_playtime, age,
	is_favorite, is_owned, times_played
) VALUES (161936, 'Pandemic Legacy: Season 1', 2015, 0, 2, 4, 60, 60, 13, 1, 0, 2);

INSERT INTO board_games (
	bgg_id, name, year_published, is_expansion,
	min_players, max_players, min_playtime, max_playtime, age,
	is_favorite, is_owned, times_played
) VALUES (174430, 'Gloomhaven', 2017, 0, 1, 4, 90, 180, 14, 0, 1, 10);

INSERT INTO board_games (
	bgg_id, name, year_published, is_expansion,
	min_players, max_players, min_playtime, max_playtime, age,
	is_favorite, is_owned, times_played
) VALUES (316554, 'Dune: Imperium', 2020, 0, 1, 4, 60, 120, 13, 1, 0, 0);

INSERT INTO board_games (
	bgg_id, name, year_published, is_expansion,
	min_players, max_players, min_playtime, max_playtime, age,
	is_favorite, is_owned, times_played
) VALUES (295895, 'Distilled', 2023, 0, 1, 5, 30, 150, 14, 0, 1, 1);

INSERT INTO categories (id, name) VALUES (1001, 'Strategy');
INSERT INTO categories (id, name) VALUES (1002, 'Economic');
INSERT INTO categories (id, name) VALUES (1003, 'Cooperative');

INSERT INTO mechanics (id, name) VALUES (2001, 'Deck Building');
INSERT INTO mechanics (id, name) VALUES (2002, 'Hand Management');
INSERT INTO mechanics (id, name) VALUES (2003, 'Campaign');

INSERT INTO board_game_categories (board_game_id, category_id) VALUES (224517, 1001);
INSERT INTO board_game_categories (board_game_id, category_id) VALUES (224517, 1002);
INSERT INTO board_game_categories (board_game_id, category_id) VALUES (342942, 1001);
INSERT INTO board_game_categories (board_game_id, category_id) VALUES (161936, 1003);
INSERT INTO board_game_categories (board_game_id, category_id) VALUES (174430, 1001);
INSERT INTO board_game_categories (board_game_id, category_id) VALUES (174430, 1003);
INSERT INTO board_game_categories (board_game_id, category_id) VALUES (316554, 1001);
INSERT INTO board_game_categories (board_game_id, category_id) VALUES (316554, 1002);
INSERT INTO board_game_categories (board_game_id, category_id) VALUES (295895, 1002);

INSERT INTO board_game_mechanics (board_game_id, mechanic_id) VALUES (224517, 2002);
INSERT INTO board_game_mechanics (board_game_id, mechanic_id) VALUES (342942, 2002);
INSERT INTO board_game_mechanics (board_game_id, mechanic_id) VALUES (161936, 2003);
INSERT INTO board_game_mechanics (board_game_id, mechanic_id) VALUES (174430, 2003);
INSERT INTO board_game_mechanics (board_game_id, mechanic_id) VALUES (316554, 2001);
INSERT INTO board_game_mechanics (board_game_id, mechanic_id) VALUES (295895, 2002);
