import 'package:sqflite/sqflite.dart';

/// Database schema definitions for the local media database.
/// Inspired by Aves gallery's robust multi-table architecture.
class LocalMediaDbSchema {
  // Table names
  static const entryTable = 'entry';
  static const metadataTable = 'metadata';
  static const addressTable = 'address';
  static const favouriteTable = 'favourites';
  static const trashTable = 'trash';
  static const videoPlaybackTable = 'videoPlayback';

  static const allTables = [
    entryTable,
    metadataTable,
    addressTable,
    favouriteTable,
    trashTable,
    videoPlaybackTable,
  ];

  /// Creates all tables for the latest schema version
  static Future<void> createLatestVersion(Database db) async {
    await Future.forEach(allTables, (table) => createTable(db, table));
  }

  /// Creates a specific table
  static Future<void> createTable(Database db, String table) {
    switch (table) {
      case entryTable:
        return db.execute('''
          CREATE TABLE $entryTable(
            contentId INTEGER PRIMARY KEY,
            uri TEXT,
            path TEXT,
            sourceMimeType TEXT,
            width INTEGER,
            height INTEGER,
            sourceRotationDegrees INTEGER,
            sizeBytes INTEGER,
            dateAddedSecs INTEGER,
            dateModifiedMillis INTEGER,
            sourceDateTakenMillis INTEGER,
            durationMillis INTEGER
          )
        ''');

      case metadataTable:
        return db.execute('''
          CREATE TABLE $metadataTable(
            id INTEGER PRIMARY KEY,
            latitude REAL,
            longitude REAL,
            xmpSubjects TEXT,
            xmpTitle TEXT,
            rating INTEGER
          )
        ''');

      case addressTable:
        return db.execute('''
          CREATE TABLE $addressTable(
            id INTEGER PRIMARY KEY,
            addressLine TEXT,
            countryCode TEXT,
            countryName TEXT,
            adminArea TEXT,
            locality TEXT
          )
        ''');

      case favouriteTable:
        return db.execute('''
          CREATE TABLE $favouriteTable(
            id INTEGER PRIMARY KEY
          )
        ''');

      case trashTable:
        return db.execute('''
          CREATE TABLE $trashTable(
            id INTEGER PRIMARY KEY,
            path TEXT,
            dateMillis INTEGER
          )
        ''');

      case videoPlaybackTable:
        return db.execute('''
          CREATE TABLE $videoPlaybackTable(
            id INTEGER PRIMARY KEY,
            resumeTimeMillis INTEGER
          )
        ''');

      default:
        throw Exception('Unknown table: $table');
    }
  }
}
