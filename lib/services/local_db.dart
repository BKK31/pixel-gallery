import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'db/db_schema.dart';
import 'db/db_migrations.dart';
import '../models/photo_model.dart';
import '../models/aves_entry.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  static Database? _db;

  factory LocalDatabase() => _instance;

  LocalDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'media.db');

    return await openDatabase(
      path,
      version: 6, // v6: added isHdr to metadata
      onCreate: (db, version) async {
        await LocalMediaDbSchema.createLatestVersion(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await LocalMediaDbMigrations.migrate(db, oldVersion, newVersion);
      },
    );
  }

  /// Loads all catalogued media from the database.
  Future<List<PhotoModel>> loadAllMedia() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(LocalMediaDbSchema.entryTable);

    return List.generate(maps.length, (i) {
      final entry = AvesEntry.fromMap(maps[i]);
      return PhotoModel(
        uid: entry.id,
        asset: entry,
        timeTaken: entry.bestDate ?? DateTime.now(),
        isVideo: entry.isVideo,
      );
    });
  }

  /// Retrieves AvesEntry objects from the database.
  Future<List<AvesEntry>> getAllEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalMediaDbSchema.entryTable,
      orderBy: 'COALESCE(NULLIF(sourceDateTakenMillis, 0), NULLIF(dateModifiedMillis, 0), dateAddedSecs * 1000, 0) DESC, contentId DESC',
    );
    return maps.map((m) => AvesEntry.fromMap(m)).toList();
  }

  /// Retrieves AvesEntry objects from the database.
  Future<Set<AvesEntry>> loadEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(LocalMediaDbSchema.entryTable);
    return maps.map((m) => AvesEntry.fromMap(m)).toSet();
  }

  /// Gets all entries that haven't been catalogued (no metadata record).
  Future<List<AvesEntry>> getUncataloguedEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM ${LocalMediaDbSchema.entryTable} e
      LEFT JOIN ${LocalMediaDbSchema.metadataTable} m ON e.contentId = m.id
      WHERE m.id IS NULL
    ''');
    return maps.map((m) => AvesEntry.fromMap(m)).toList();
  }

  /// Gets a single entry by ID.
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

  /// Gets specific entries by content IDs.
  Future<List<AvesEntry>> getEntriesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalMediaDbSchema.entryTable,
      where: 'contentId IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
    return maps.map((m) => AvesEntry.fromMap(m)).toList();
  }

  /// Saves or updates a set of AvesEntry objects in the database.
  Future<void> saveEntries(List<AvesEntry> entries) async {
    final db = await database;
    final batch = db.batch();

    for (var entry in entries) {
      batch.insert(
        LocalMediaDbSchema.entryTable,
        _entryToDatabaseMap(entry),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Bulk delete entries by content ID.
  Future<void> deleteEntries(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final batch = db.batch();

    for (var id in ids) {
      batch.delete(
        LocalMediaDbSchema.entryTable,
        where: 'contentId = ?',
        whereArgs: [id],
      );
      batch.delete(
        LocalMediaDbSchema.metadataTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      batch.delete(
        LocalMediaDbSchema.addressTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
  }

  /// Gets contentId -> dateModifiedMillis map for all known entries.
  Future<Map<int, int>> getKnownEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalMediaDbSchema.entryTable,
      columns: ['contentId', 'dateModifiedMillis'],
    );
    return {for (var m in maps) m['contentId'] as int: m['dateModifiedMillis'] as int};
  }

  /// Loads metadata for specific content IDs.
  Future<Map<int, Map<String, dynamic>>> loadMetadataByIds(List<int> ids) async {
    if (ids.isEmpty) return {};
    final db = await database;
    
    // Chunking to avoid sqlite limit
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += 900) {
      final chunk = ids.sublist(i, i + 900 > ids.length ? ids.length : i + 900);
      results.addAll(await db.query(
        LocalMediaDbSchema.metadataTable,
        where: 'id IN (${List.filled(chunk.length, '?').join(',')})',
        whereArgs: chunk,
      ));
    }

    final metadataMap = <int, Map<String, dynamic>>{};
    for (var row in results) {
      metadataMap[row['id'] as int] = row;
    }
    return metadataMap;
  }

  /// Loads addresses for specific content IDs.
  Future<Map<int, Map<String, dynamic>>> loadAddressesByIds(List<int> ids) async {
    if (ids.isEmpty) return {};
    final db = await database;

    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += 900) {
      final chunk = ids.sublist(i, i + 900 > ids.length ? ids.length : i + 900);
      results.addAll(await db.query(
        LocalMediaDbSchema.addressTable,
        where: 'id IN (${List.filled(chunk.length, '?').join(',')})',
        whereArgs: chunk,
      ));
    }

    final addressMap = <int, Map<String, dynamic>>{};
    for (var row in results) {
      addressMap[row['id'] as int] = row;
    }
    return addressMap;
  }

  /// Saves metadata for a media entry.
  Future<void> saveMetadata(int contentId, Map<String, dynamic> metadata) async {
    final db = await database;
    await db.insert(
      LocalMediaDbSchema.metadataTable,
      {
        'id': contentId,
        'latitude': metadata['latitude'],
        'longitude': metadata['longitude'],
        'make': metadata['make'],
        'model': metadata['model'],
        'xmpSubjects': metadata['xmpSubjects'],
        'xmpTitle': metadata['xmpTitle'],
        'rating': metadata['rating'],
        'isHdr': metadata['isHdr'] == true ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Saves address for a media entry.
  Future<void> saveAddress(int contentId, Map<String, dynamic> address) async {
    final db = await database;
    await db.insert(
      LocalMediaDbSchema.addressTable,
      {
        'id': contentId,
        'addressLine': address['addressLine'],
        'countryCode': address['countryCode'],
        'countryName': address['countryName'],
        'adminArea': address['adminArea'],
        'locality': address['locality'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Loads all favorites from the database.
  Future<Set<int>> loadFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(LocalMediaDbSchema.favouriteTable);
    return maps.map((m) => m['id'] as int).toSet();
  }

  /// Gets all favorite IDs.
  Future<List<int>> getAllFavoriteIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalMediaDbSchema.favouriteTable,
      columns: ['id'],
    );
    return maps.map((m) => m['id'] as int).toList();
  }

  /// Gets complete AvesEntry objects for all favorites.
  Future<List<AvesEntry>> getFavoriteEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM ${LocalMediaDbSchema.entryTable} e
      INNER JOIN ${LocalMediaDbSchema.favouriteTable} f ON e.contentId = f.id
      ORDER BY e.dateModifiedMillis DESC
    ''');
    return maps.map((m) => AvesEntry.fromMap(m)).toList();
  }

  /// Adds a favorite media entry.
  Future<void> addFavorite(int contentId) async {
    final db = await database;
    await db.insert(
      LocalMediaDbSchema.favouriteTable,
      {'id': contentId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Removes a favorite media entry.
  Future<void> removeFavorite(int contentId) async {
    final db = await database;
    await db.delete(
      LocalMediaDbSchema.favouriteTable,
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }

  /// Clears all favorites (for debugging or user request).
  Future<void> clearAllFavorites() async {
    final db = await database;
    await db.delete(LocalMediaDbSchema.favouriteTable);
  }

  /// Clears all metadata entries (for forced re-cataloging after an update)
  Future<void> clearAllMetadata() async {
    final db = await database;
    await db.delete(LocalMediaDbSchema.metadataTable);
  }

  /// Gets the isHdr flag for a given content ID.
  Future<bool> isHdr(int? contentId) async {
    if (contentId == null) return false;
    final db = await database;
    final result = await db.query(
      LocalMediaDbSchema.metadataTable,
      columns: ['isHdr'],
      where: 'id = ?',
      whereArgs: [contentId],
    );
    if (result.isEmpty) return false;
    return (result.first['isHdr'] as int? ?? 0) != 0;
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
