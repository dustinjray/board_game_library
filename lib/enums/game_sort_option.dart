enum GameSortOption {
  nameAsc,
  nameDesc,
  datePlayedAsc,
  datePlayedDesc,
  leastPlayed,
  mostPlayed,
  mostPlayers,
  leastPlayers,
  longestPlaytime,
  shortestPlaytime;

  String get label {
    switch (this) {
      case GameSortOption.nameDesc:
        return 'Name (Z-A)';
      case GameSortOption.datePlayedAsc:
        return 'Date Played (Oldest)';
      case GameSortOption.datePlayedDesc:
        return 'Date Played (Newest)';
      case GameSortOption.leastPlayed:
        return 'Least Played';
      case GameSortOption.mostPlayed:
        return 'Most Played';
      case GameSortOption.mostPlayers:
        return 'Most Players';
      case GameSortOption.leastPlayers:
        return 'Least Players';
      case GameSortOption.longestPlaytime:
        return 'Longest Playtime';
      case GameSortOption.shortestPlaytime:
        return 'Shortest Playtime';
      case GameSortOption.nameAsc:
        return 'Name (A-Z)';
    }
  }
}