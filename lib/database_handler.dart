import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path/path.dart';

import 'package:path_provider/path_provider.dart';

// Database table and column names
final String tableGyroReadings = 'gyro';
final String columnId = '_id';
final String columnData = 'data';

// Data model class
class Data {
  int id;
  String data;

  Data();

  // Method to create Data
  Data.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    data = map[columnData];
  }

  // Method to create Map object from Data
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnData: data,
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }
}

// Singleton class to manage the database
class DatabaseHandler {
  // This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "MyDatabase.db";

  // Increment this version when you need to change the schema.
  static final _databaseVersion = 1;

  // Make this a singleton class.
  DatabaseHandler._privateConstructor();

  static final DatabaseHandler instance = DatabaseHandler._privateConstructor();

  // Only allow a single open connection to the database.
  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // Open the database
  _initDatabase() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    // Open the database. Can also add an onUpdate callback parameter.
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL string to create the database
  Future _onCreate(Database db, int version) async {
    await db.execute('''
              CREATE TABLE $tableGyroReadings (
                $columnId INTEGER PRIMARY KEY,
                $columnData TEXT NOT NULL
              )
              ''');
  }

  // Database helper methods:
  Future<int> insert(Data data) async {
    Database db = await database;
    int id = await db.insert(tableGyroReadings, data.toMap());
    return id;
  }

  Future<Data> queryWord(int id) async {
    Database db = await database;
    List<Map> maps = await db.query(tableGyroReadings,
        columns: [columnId, columnData],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return Data.fromMap(maps.first);
    }
    return null;
  }

  queryAllData() async {
    Database db = await database;
    List<Map> maps = await db.rawQuery("SELECT * FROM $tableGyroReadings");
    return maps;
  }

  deleteAllData() async {
    Database db = await database;
    await db.rawQuery("DELETE FROM $tableGyroReadings");
  }
}
