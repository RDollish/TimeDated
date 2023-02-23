import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = 'my_database.db';
  static const _databaseVersion = 1;

  static const userTable = 'user_info';
  static const userColumnId = 'id';
  static const userColumnFireBaseId = 'firebase_id';
  static const userColumnEmail = 'email';

  static const remindersTable = 'reminders';
  static const remindersColumnId = 'id';
  static const remindersColumnName = 'name';
  static const remindersColumnStreak = 'streak';
  static const remindersColumnUserId = 'user_id';

  static const achievementsTable = 'achievements';
  static const achievementsColumnId = 'id';
  static const achievementsColumnName = 'name';
  static const achievementsColumnStreak = 'streak';

  DatabaseHelper._privateConstructor();
  static DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $userTable (
            $userColumnId INTEGER PRIMARY KEY,
            $userColumnFireBaseId STRING NOT NULL,
            $userColumnEmail TEXT NOT NULL
          )
          ''');

    await db.execute('''
          CREATE TABLE $remindersTable (
            $remindersColumnId INTEGER PRIMARY KEY,
            $remindersColumnName TEXT NOT NULL,
            $remindersColumnStreak INTEGER NOT NULL,
            $remindersColumnUserId INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY ($remindersColumnUserId) REFERENCES $userTable($userColumnId)
          )
          ''');

    await db.execute('''
          CREATE TABLE $achievementsTable (
            $achievementsColumnId INTEGER PRIMARY KEY,
            $achievementsColumnName TEXT NOT NULL,
            $achievementsColumnStreak INTEGER NOT NULL
          )
          ''');

    await db.execute('''
          INSERT INTO $achievementsTable ($achievementsColumnName, $achievementsColumnStreak)
          VALUES 
            ('One Day at a Time', 1),
            ('Two In A Row!', 2),
            ('Three-rific!', 3),
            ('Four-ward Progress!', 4),
            ('Five-tastic!', 5),
            ('Six-cess Achiever!', 6),
            ('Lucky Seven Streak!', 7)
          ''');
  }

  Future<int> insertReminder(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(remindersTable, row);
  }

  Future<List<Map<String, dynamic>>> getAllReminders() async {
    Database db = await instance.database;
    return await db.query(remindersTable);
  }

  Future<int> updateReminder(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[remindersColumnId];
    return await db.update(
      remindersTable,
      row,
      where: '$remindersColumnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteReminder(int id) async {
    Database db = await instance.database;
    return await db.delete(
      remindersTable,
      where: '$remindersColumnId = ?',
      whereArgs: [id],
    );
    
  }  Future<int> insertUser({
    required String firebaseId,
    required String email,
  }) async {
    Database db = await instance.database;
    Map<String, dynamic> row = {
      userColumnFireBaseId: firebaseId,
      userColumnEmail: email,
    };
    return await db.insert(userTable, row);
  }
}
