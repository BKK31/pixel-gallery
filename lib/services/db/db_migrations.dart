import 'package:sqflite/sqflite.dart';
import 'db_schema.dart';

/// Handles database migrations from old schema versions to new ones.
class LocalMediaDbMigrations {
  /// Migrates database from old version to new version
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 4 && newVersion >= 4) {
      await _migrateToV4(db);
    }
  }

  /// Migration from v3 (single table) to v4 (multi-table schema)
  static Future<void> _migrateToV4(Database db) async {
    // Step 1: Read all existing data from old 'entries' table
    final List<Map<String, dynamic>> existingEntries = await db.query(
      'entries',
    );

    // Step 2: Rename old table as backup
    await db.execute('ALTER TABLE entries RENAME TO entries_old');

    // Step 3: Create all new tables
    await LocalMediaDbSchema.createLatestVersion(db);

    // Step 4: Migrate data to new schema
    final batch = db.batch();

    for (final entry in existingEntries) {
      final contentId = entry['contentId'] as int?;
      if (contentId == null) continue;

      // Insert into entry table (core data only)
      batch.insert(
        LocalMediaDbSchema.entryTable,
        {
          'contentId': contentId,
          'uri': entry['uri'],
          'path': entry['path'],
          'sourceMimeType': entry['sourceMimeType'],
          'width': entry['width'],
          'height': entry['height'],
          'sourceRotationDegrees': entry['sourceRotationDegrees'],
          'sizeBytes': entry['sizeBytes'],
          'dateAddedSecs': entry['dateAddedSecs'],
          'dateModifiedMillis': entry['dateModifiedMillis'],
          'sourceDateTakenMillis': entry['sourceDateTakenMillis'],
          'durationMillis': entry['durationMillis'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // If entry was catalogued (has lat/long), insert into metadata table
      final isCatalogued = (entry['isCatalogued'] as int? ?? 0) == 1;
      final latitude = entry['latitude'] as double?;
      final longitude = entry['longitude'] as double?;

      if (isCatalogued || (latitude != null && longitude != null)) {
        batch.insert(
          LocalMediaDbSchema.metadataTable,
          {
            'id': contentId,
            'latitude': latitude,
            'longitude': longitude,
            'xmpSubjects': null,
            'xmpTitle': null,
            'rating': null,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // If entry was a favorite, insert into favourites table
      final isFavorite = (entry['isFavorite'] as int? ?? 0) == 1;
      if (isFavorite) {
        batch.insert(
          LocalMediaDbSchema.favouriteTable,
          {'id': contentId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit(noResult: true);

    // Step 5: Drop old backup table
    await db.execute('DROP TABLE IF EXISTS entries_old');
  }
}
