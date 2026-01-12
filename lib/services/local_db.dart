import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/aves_entry.dart';

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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
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
            durationMillis INTEGER,
            latitude REAL,
            longitude REAL,
            isCatalogued INTEGER DEFAULT 0,
            isFavorite INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE entries ADD COLUMN latitude REAL');
          await db.execute('ALTER TABLE entries ADD COLUMN longitude REAL');
          await db.execute(
            'ALTER TABLE entries ADD COLUMN isCatalogued INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE entries ADD COLUMN isFavorite INTEGER DEFAULT 0',
          );
        }
      },
    );
  }

  Future<void> saveEntries(List<AvesEntry> entries) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in entries) {
      if (entry.contentId == null) continue;
      batch.insert(
        'entries',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AvesEntry>> getAllEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      orderBy: 'dateModifiedMillis DESC',
    );
    return maps.map((map) => AvesEntry.fromMap(map)).toList();
  }

  Future<Map<int?, int?>> getKnownEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      columns: ['contentId', 'dateModifiedMillis'],
    );
    return {
      for (final map in maps)
        map['contentId'] as int?: map['dateModifiedMillis'] as int?,
    };
  }

  Future<List<AvesEntry>> getUncataloguedEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      where: 'isCatalogued = 0',
    );
    return maps.map((map) => AvesEntry.fromMap(map)).toList();
  }

  Future<List<AvesEntry>> getFavoriteEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      where: 'isFavorite = 1',
      orderBy: 'dateModifiedMillis DESC',
    );
    return maps.map((map) => AvesEntry.fromMap(map)).toList();
  }

  Future<AvesEntry?> getEntry(int contentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      where: 'contentId = ?',
      whereArgs: [contentId],
    );
    if (maps.isEmpty) return null;
    return AvesEntry.fromMap(maps.first);
  }

  Future<void> updateEntry(AvesEntry entry) async {
    if (entry.contentId == null) return;
    final db = await database;
    await db.update(
      'entries',
      entry.toMap(),
      where: 'contentId = ?',
      whereArgs: [entry.contentId],
    );
  }

  Future<void> deleteEntries(List<int> contentIds) async {
    if (contentIds.isEmpty) return;
    final db = await database;
    await db.delete('entries', where: 'contentId IN (${contentIds.join(',')})');
  }

  Future<List<AvesEntry>> getEntriesByIds(List<int> contentIds) async {
    if (contentIds.isEmpty) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      where: 'contentId IN (${contentIds.join(',')})',
      orderBy: 'dateModifiedMillis DESC',
    );
    return maps.map((map) => AvesEntry.fromMap(map)).toList();
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('entries');
  }
}
