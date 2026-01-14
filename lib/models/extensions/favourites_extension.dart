import '../../models/aves_entry.dart';
import '../../services/favourites_manager.dart';

/// Extension on AvesEntry to add favorite functionality.
/// Uses the global FavouritesManager singleton for instant lookups.
extension AvesEntryFavoritesExtension on AvesEntry {
  /// Returns whether this entry is marked as a favorite
  bool get isFavorite => favouritesManager.isFavorite(this);

  /// Toggles the favorite status of this entry
  Future<void> toggleFavorite() async {
    await favouritesManager.toggle(this);
  }
}
