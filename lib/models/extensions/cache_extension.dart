import '../../models/aves_entry.dart';
import '../../services/entry_cache.dart';

/// Extension on AvesEntry to provide cache eviction methods.
/// Call when entry's visual properties change (rotation, edits, etc).
extension AvesEntryCacheExtension on AvesEntry {
  /// Evicts all cached images for this entry from Flutter's image cache.
  Future<void> evictCache() async {
    await EntryCache.evict(
      uri: uri,
      dateModifiedMillis: dateModifiedMillis ?? 0,
    );
  }
}
