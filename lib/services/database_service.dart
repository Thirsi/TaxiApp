import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import '../models/job.dart';
import 'settings_service.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'taxi_jobs.db';
  static const int _dbVersion = 3;
  final SettingsService _settings;

  DatabaseService(this._settings);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE jobs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        startMileage REAL NOT NULL,
        endMileage REAL,
        price REAL NOT NULL,
        paymentType TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE jobs ADD COLUMN price REAL NOT NULL DEFAULT 0.0');
    }
    if (oldVersion < 3) {
      // Make endMileage nullable
      await db.execute('ALTER TABLE jobs RENAME TO jobs_old');
      await _createDb(db, newVersion);
      await db.execute('''
        INSERT INTO jobs (id, date, startMileage, endMileage, price, paymentType, notes)
        SELECT id, date, startMileage, endMileage, price, paymentType, notes
        FROM jobs_old
      ''');
      await db.execute('DROP TABLE jobs_old');
    }
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _dbName);
    
    // Delete existing database if it's corrupted
    try {
      final db = await openDatabase(path);
      await db.close();
    } catch (e) {
      await databaseFactory.deleteDatabase(path);
    }
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<int> insertJob(Job job) async {
    try {
      final db = await database;
      return await db.insert('jobs', job.toMap());
    } catch (e) {
      throw Exception('Failed to insert job: $e');
    }
  }

  Future<List<Job>> getJobs() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'jobs',
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => Job.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get jobs: $e');
    }
  }

  Future<List<DailySummary>> getDailySummaries() async {
    try {
      final jobs = await getJobs();
      
      // Group jobs by date (ignoring time)
      final Map<String, List<Job>> jobsByDate = {};
      for (final job in jobs) {
        final dateKey = job.date.toIso8601String().split('T')[0];
        jobsByDate.putIfAbsent(dateKey, () => []).add(job);
      }

      // Create summaries for each date
      return jobsByDate.values
          .map((dayJobs) => DailySummary.fromJobs(dayJobs, _settings))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
    } catch (e) {
      throw Exception('Failed to get daily summaries: $e');
    }
  }

  Future<String> exportToCsv() async {
    try {
      final jobs = await getJobs();
      final csvData = [
        Job.csvHeaders(),
        ...jobs.map((job) => job.toCsvRow(_settings)),
      ];

      final String csv = const ListToCsvConverter().convert(csvData);
      
      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/taxi_jobs_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      final File file = File(path);
      await file.writeAsString(csv);
      
      return path;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  Future<void> clearDatabase() async {
    final String path = join(await getDatabasesPath(), _dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
