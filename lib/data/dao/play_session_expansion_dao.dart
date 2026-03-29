import 'package:sqflite/sqflite.dart';

abstract class PlaySessionExpansionDAO {
  Future<List<int>> getExpansionIdsForSession(int playSessionId);
  Future<List<int>> getSessionIdsForExpansion(int expansionId);
  Future<int> linkExpansionToSession(int playSessionId, int expansionId);
  Future<int> unlinkExpansionFromSession(int playSessionId, int expansionId);
  Future<int> deleteLinksForSession(int playSessionId);
  Future<int> countSessionsForExpansion(int expansionId);

  Future<void> replaceExpansionsForSessionInTransaction(
    Transaction txn,
    int playSessionId,
    List<int> expansionIds,
  );
}
