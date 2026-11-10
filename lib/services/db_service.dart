import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/schedule.dart';

class DbService {
  static final DbService instance = DbService._init();
  static Database? _database;

  DbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('masteran_burung.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        platform TEXT NOT NULL,
        videoId TEXT NOT NULL,
        startHour INTEGER NOT NULL,
        startMinute INTEGER NOT NULL,
        endHour INTEGER NOT NULL,
        endMinute INTEGER NOT NULL,
        daysOfWeek TEXT NOT NULL,
        isActive INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertSchedule(Schedule schedule) async {
    final db = await database;
    return await db.insert('schedules', schedule.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSchedule(Schedule schedule) async {
    final db = await database;
    return await db.update('schedules', schedule.toMap(), where: 'id = ?', whereArgs: [schedule.id]);
  }

  Future<int> deleteSchedule(String id) async {
    final db = await database;
    return await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Schedule>> getAllSchedules() async {
    final db = await database;
    final result = await db.query('schedules', orderBy: 'startHour ASC, startMinute ASC');
    return result.map((json) => Schedule.fromMap(json)).toList();
  }

  Future<int> toggleScheduleActive(String id, bool isActive) async {
    final db = await database;
    return await db.update('schedules', {'isActive': isActive ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }
}