import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/aves_entry.dart';
import 'db/db_schema.dart';
import 'db/db_migrations.dart';

/// Local database for storing media entries and associated metadata.
/// Uses a multi-table schema inspired by Aves for better data organization.
class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gallery_index.db');

    return await openDatabase(
      path,
      version: 4, // New version with multi-table schema
      onCreate: (db, version) async {
        await LocalMediaDbSchema.createLatestVersion(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await LocalMediaDbMigrations.migrate(db, oldVersion, newVersion);
      },
    );
  }

  // ========== Entry Operations ==========

  /// Saves multiple entries using batch operations for performance
  Future<void> saveEntries(List<AvesEntry> entries) async {
    if (entries.isEmpty) return;
    final db = await database;
    final batch = db.batch();

    for (final entry in entries) {
      if (entry.contentId == null) continue;

      batch.insert(
        LocalMediaDbSchema.entryTable,
        _entryToDatabaseMap(entry),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Loads all entries from the database
  Future<List<AvesEntry>> getAllEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalMediaDbSchema.entryTable,
      orderBy: 'dateModifiedMillis DESC',
    );
    return maps.map((map) => AvesEntry.fromMap(map)).toList();
  }

  /// Quickly gets the most recent entries (limited) for Fast Path loading
  Future<List<AvesEntry>> getLatestEntries({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalMediaDbSchema.entryTable,
      orderBy: 'dateModifiedMillis DESC',
      limit: limit,
    );
    return maps.map((map) => AvesEntry.fromMap(map)).toList();
  }

  /// Gets a map of known entries (contentId -> dateModifiedMillis)
  Future<Map<int?, int?>> getKnownEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalMediaDbSchema.entryTable,
      columns: ['contentId', 'dateModifiedMillis'],
    );
    return {
      for (final map in maps)
        map['contentId'] as int?: map['dateModifiedMillis'] as int?,
    };
  }

  /// Gets entries that haven't been catalogued yet (no metadata)
  Future<List<AvesEntry>> getUncataloguedEntries() async {
    final db = await database;

    // Entries that don't have a corresponding row in metadata table
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM ${LocalMediaDbSchema.entryTable} 
      WHERE contentId NOT IN (
        SELECT id FROM ${LocalMediaDbSchema.metadataTable}
      )
      ORDER BY dateModifiedMillis DESC
    ''');

    return maps.map((map) => AvesEntry.fromMap(map)).toList();
  }

  /// Gets a single entry by contentId
  Future<AvesEntry?> getEntry(int contentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalMediaDbSchema.entryTable,
      where: 'contentId = ?',
      whereArgs: [contentId],
    );
    if (maps.isEmpty) return null;
    return AvesEntry.fromMap(maps.first);
  }

  /// Gets multiple entries by their IDs
  Future<List<AvesEntry>> getEntriesByIds(List<int> contentIds) async {
    if (contentIds.isEmpty) return [];
    final db = await database;
    final placeholders = List.filled(contentIds.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      LocalMediaDbSchema.entryTable,
      where: 'contentId IN ($placeholders)',
      whereArgs: contentIds,
      orderBy: 'dateModifiedMillis DESC',
    );
    return maps.map((map) => AvesEntry.fromMap(map)).toList();
  }

  /// Updates an existing entry
  Future<void> updateEntry(AvesEntry entry) async {
    if (entry.contentId == null) return;
    final db = await database;
    await db.update(
      LocalMediaDbSchema.entryTable,
      _entryToDatabaseMap(entry),
      where: 'contentId = ?',
      whereArgs: [entry.contentId],
    );
  }

  /// Deletes entries by their IDs
  Future<void> deleteEntries(List<int> contentIds) async {
    if (contentIds.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(contentIds.length, '?').join(',');

    final batch = db.batch();

    // Delete from all related tables
    batch.delete(
      LocalMediaDbSchema.entryTable,
      where: 'contentId IN ($placeholders)',
      whereArgs: contentIds,
    );
    batch.delete(
      LocalMediaDbSchema.metadataTable,
      where: 'id IN ($placeholders)',
      whereArgs: contentIds,
    );
    batch.delete(
      LocalMediaDbSchema.addressTable,
      where: 'id IN ($placeholders)',
      whereArgs: contentIds,
    );
    batch.delete(
      LocalMediaDbSchema.favouriteTable,
      where: 'id IN ($placeholders)',
      whereArgs: contentIds,
    );
    batch.delete(
      LocalMediaDbSchema.videoPlaybackTable,
      where: 'id IN ($placeholders)',
      whereArgs: contentIds,
    );

    await batch.commit(noResult: true);
  }

  // ========== Metadata Operations ==========

  /// Saves metadata for entries (GPS, EXIF data)
  Future<void> saveMetadata(
    int contentId,
    Map<String, dynamic> metadata,
  ) async {
    final db = await database;
    await db.insert(
      LocalMediaDbSchema.metadataTable,
      {
        'id': contentId,
        'latitude': metadata['latitude'],
        'longitude': metadata['longitude'],
        'xmpSubjects': metadata['xmpSubjects'],
        'xmpTitle': metadata['xmpTitle'],
        'rating': metadata['rating'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Loads metadata for multiple entries
  Future<Map<int, Map<String, dynamic>>> loadMetadataByIds(
    List<int> ids,
  ) async {
    if (ids.isEmpty) return {};
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      LocalMediaDbSchema.metadataTable,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return {for (final map in maps) map['id'] as int: map};
  }

  // ========== Favorites Operations ==========

  /// Gets all favorite entries
  Future<List<AvesEntry>> getFavoriteEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM ${LocalMediaDbSchema.entryTable} e
      INNER JOIN ${LocalMediaDbSchema.favouriteTable} f ON e.contentId = f.id
      ORDER BY e.dateModifiedMillis DESC
    ''');
    return maps.map((map) => AvesEntry.fromMap(map)).toList();
  }

  /// Checks if an entry is a favorite
  Future<bool> isFavorite(int contentId) async {
    final db = await database;
    final result = await db.query(
      LocalMediaDbSchema.favouriteTable,
      where: 'id = ?',
      whereArgs: [contentId],
    );
    return result.isNotEmpty;
  }

  /// Adds an entry to favorites
  Future<void> addFavorite(int contentId) async {
    final db = await database;
    await db.insert(
      LocalMediaDbSchema.favouriteTable,
      {'id': contentId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Removes an entry from favorites
  Future<void> removeFavorite(int contentId) async {
    final db = await database;
    await db.delete(
      LocalMediaDbSchema.favouriteTable,
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }

  /// Toggles favorite status for an entry
  Future<bool> toggleFavorite(int contentId) async {
    final isCurrentlyFavorite = await isFavorite(contentId);
    if (isCurrentlyFavorite) {
      await removeFavorite(contentId);
      return false;
    } else {
      await addFavorite(contentId);
      return true;
    }
  }

  // ========== Utility Methods ==========

  /// Clears all data from the database
  Future<void> clearAll() async {
    final db = await database;
    final batch = db.batch();
    for (final table in LocalMediaDbSchema.allTables) {
      batch.delete(table);
    }
    await batch.commit(noResult: true);
  }

  /// Gets all favorite IDs (for FavouritesManager initialization)
  Future<List<int>> getAllFavoriteIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalMediaDbSchema.favouriteTable,
      columns: ['id'],
    );
    return maps.map((map) => map['id'] as int).toList();
  }

  /// Clears all favorites
  Future<void> clearAllFavorites() async {
    final db = await database;
    await db.delete(LocalMediaDbSchema.favouriteTable);
  }

  /// Converts an AvesEntry to a database map (entry table only)
  Map<String, dynamic> _entryToDatabaseMap(AvesEntry entry) {
    return {
      'contentId': entry.contentId,
      'uri': entry.uri,
      'path': entry.path,
      'sourceMimeType': entry.sourceMimeType,
      'width': entry.width,
      'height': entry.height,
      'sourceRotationDegrees': entry.sourceRotationDegrees,
      'sizeBytes': entry.sizeBytes,
      'dateAddedSecs': entry.dateAddedSecs,
      'dateModifiedMillis': entry.dateModifiedMillis,
      'sourceDateTakenMillis': entry.sourceDateTakenMillis,
      'durationMillis': entry.durationMillis,
    };
  }
}
