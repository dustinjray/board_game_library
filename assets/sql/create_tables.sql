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
  is_owned INTEGER NOT NULL DEFAULT 0,
  details_fetched INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_board_games_name_nocase
ON board_games(name COLLATE NOCASE);

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

CREATE TABLE play_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    board_game_id INTEGER NOT NULL,
    date_played TEXT NOT NULL,
    FOREIGN KEY (board_game_id) REFERENCES board_games (bgg_id) ON DELETE CASCADE
);

CREATE TABLE players (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

CREATE TABLE play_session_scores (
    play_session_id INTEGER NOT NULL,
    player_id INTEGER NOT NULL,
    score INTEGER,
    is_winner INTEGER DEFAULT 0,
    PRIMARY KEY (play_session_id, player_id),
    FOREIGN KEY (play_session_id) REFERENCES play_sessions (id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
);

CREATE TABLE play_session_expansions (
    play_session_id INTEGER NOT NULL,
    expansion_id INTEGER NOT NULL,
    PRIMARY KEY (play_session_id, expansion_id),
    FOREIGN KEY (play_session_id) REFERENCES play_sessions (id) ON DELETE CASCADE,
    FOREIGN KEY (expansion_id) REFERENCES expansions (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_play_session_expansions_session
ON play_session_expansions(play_session_id);

CREATE INDEX IF NOT EXISTS idx_play_session_expansions_expansion
ON play_session_expansions(expansion_id);