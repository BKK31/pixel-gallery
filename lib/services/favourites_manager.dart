import 'package:flutter/foundation.dart';
import '../models/aves_entry.dart';
import 'local_db.dart';

/// Global singleton for managing favorites in memory.
/// Inspired by Aves's Favourites class - loads all favorites at startup
/// for instant O(1) lookups without database queries.
final FavouritesManager favouritesManager = FavouritesManager._private();

class FavouritesManager with ChangeNotifier {
  Set<int> _favoriteIds = {};
  final LocalDatabase _db = LocalDatabase();

  FavouritesManager._private();

  /// Initializes the favorites manager by loading all favorite IDs from database
  Future<void> init() async {
    _favoriteIds = (await _db.getAllFavoriteIds()).toSet();
  }

  /// Returns the count of favorites
  int get count => _favoriteIds.length;

  /// Returns all favorite IDs
  Set<int> get all => Set.unmodifiable(_favoriteIds);

  /// Checks if an entry is a favorite (O(1) lookup)
  bool isFavorite(AvesEntry entry) {
    if (entry.contentId == null) return false;
    return _favoriteIds.contains(entry.contentId);
  }

  /// Adds entries to favorites
  Future<void> add(Set<AvesEntry> entries) async {
    final newIds = entries
        .where((e) => e.contentId != null)
        .map((e) => e.contentId!)
        .toSet();

    if (newIds.isEmpty) return;

    // Add to database
    for (final id in newIds) {
      await _db.addFavorite(id);
    }

    // Update in-memory set
    _favoriteIds.addAll(newIds);

    // Notify listeners for reactive UI updates
    notifyListeners();
  }

  /// Removes entries from favorites
  Future<void> remove(Set<AvesEntry> entries) async {
    final removeIds = entries
        .where((e) => e.contentId != null)
        .map((e) => e.contentId!)
        .toSet();

    if (removeIds.isEmpty) return;

    // Remove from database
    for (final id in removeIds) {
      await _db.removeFavorite(id);
    }

    // Update in-memory set
    _favoriteIds.removeAll(removeIds);

    // Notify listeners for reactive UI updates
    notifyListeners();
  }

  /// Toggles favorite status for an entry
  Future<bool> toggle(AvesEntry entry) async {
    if (entry.contentId == null) return false;

    if (isFavorite(entry)) {
      await remove({entry});
      return false;
    } else {
      await add({entry});
      return true;
    }
  }

  /// Clears all favorites
  Future<void> clear() async {
    await _db.clearAllFavorites();
    _favoriteIds.clear();
    notifyListeners();
  }
}
