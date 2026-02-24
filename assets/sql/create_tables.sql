CREATE TABLE board_games (
  bgg_id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
    year_published INTEGER,
  is_expansion INTEGER NOT NULL DEFAULT 0,
  min_players INTEGER,
  max_players INTEGER,
  min_playtime INTEGER,
  max_playtime INTEGER,
  age INTEGER,
  description TEXT,
  thumbnail TEXT,
  image TEXT,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  times_played INTEGER NOT NULL DEFAULT 0,
  is_owned INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE categories (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE mechanics (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE expansions (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE board_game_categories (
    board_game_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    PRIMARY KEY (board_game_id, category_id),
    FOREIGN KEY (board_game_id) REFERENCES board_games (bgg_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
);

CREATE TABLE board_game_mechanics (
    board_game_id INTEGER NOT NULL,
    mechanic_id INTEGER NOT NULL,
    PRIMARY KEY (board_game_id, mechanic_id),
    FOREIGN KEY (board_game_id) REFERENCES board_games (bgg_id) ON DELETE CASCADE,
    FOREIGN KEY (mechanic_id) REFERENCES mechanics (id) ON DELETE CASCADE
);

CREATE TABLE board_game_expansions (
    board_game_id INTEGER NOT NULL,
    expansion_id INTEGER NOT NULL,
    PRIMARY KEY (board_game_id, expansion_id),
    FOREIGN KEY (board_game_id) REFERENCES board_games (bgg_id) ON DELETE CASCADE,
    FOREIGN KEY (expansion_id) REFERENCES expansions (id) ON DELETE CASCADE
);

CREATE TABLE players (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

CREATE TABLE play_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    board_game_id INTEGER NOT NULL,
    date_played DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    winner_id INTEGER,
    FOREIGN KEY (board_game_id) REFERENCES board_games (bgg_id) ON DELETE CASCADE,
    FOREIGN KEY (winner_id) REFERENCES players (id) ON DELETE SET NULL
);

CREATE TABLE play_session_players (
    play_session_id INTEGER NOT NULL,
    player_id INTEGER NOT NULL,
    player_score INTEGER,
    PRIMARY KEY (play_session_id, player_id),
    FOREIGN KEY (play_session_id) REFERENCES play_sessions (id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
);