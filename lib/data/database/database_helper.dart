import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _databaseName = 'hoc_tot.db';
  static const int _databaseVersion = 1;

  Database? _database;
  Future<Database>? _databaseFuture;

  // Get database instance.
  // Reuse the same initialization process if multiple calls happen together.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _databaseFuture ??= _initDatabase()
        .then((db) {
          _database = db;
          return db;
        })
        .catchError((error) {
          _databaseFuture = null;
          throw error;
        });

    return _databaseFuture!;
  }

  // Initialize database.
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final pathToDatabase = join(databasePath, _databaseName);

    return openDatabase(
      pathToDatabase,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  // Enable foreign key constraints.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Create database tables.
  Future<void> _onCreate(Database db, int version) async {
    // 1. Subjects
    await db.execute('''
      CREATE TABLE subjects (
        subject_code TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lecturer TEXT,
        description TEXT,
        color TEXT NOT NULL
      )
    ''');

    // 2. Assignments
    await db.execute('''
      CREATE TABLE assignments (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subject_code TEXT NOT NULL,
        assigned_date TEXT NOT NULL,
        deadline TEXT NOT NULL,
        description TEXT,
        note TEXT,
        status TEXT NOT NULL
          CHECK (
            status IN ('completed', 'incomplete')
          ),

        FOREIGN KEY (subject_code)
          REFERENCES subjects(subject_code)
          ON DELETE RESTRICT,

        CHECK (date(assigned_date) IS NOT NULL),
        CHECK (
          date(deadline) >= date(assigned_date)
        )
      )
    ''');

    // 3. Schedules
    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        subject_code TEXT NOT NULL,
        weekday INTEGER NOT NULL
          CHECK (weekday BETWEEN 1 AND 7),
        start_time INTEGER NOT NULL
          CHECK (start_time BETWEEN 0 AND 1439),
        end_time INTEGER NOT NULL
          CHECK (end_time BETWEEN 1 AND 1439),
        location TEXT,

        FOREIGN KEY (subject_code)
          REFERENCES subjects(subject_code)
          ON DELETE RESTRICT,

        CHECK (end_time > start_time)
      )
    ''');

    // 4. Reminders
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        assignment_id TEXT NOT NULL,
        reminder_type TEXT NOT NULL
          CHECK (
            reminder_type IN (
              'oneDayBefore',
              'oneHourBefore'
            )
          ),
        scheduled_at TEXT NOT NULL,
        notification_id INTEGER NOT NULL UNIQUE,
        is_scheduled INTEGER NOT NULL
          CHECK (is_scheduled IN (0, 1)),

        FOREIGN KEY (assignment_id)
          REFERENCES assignments(id)
          ON DELETE CASCADE
      )
    ''');

    // 5. App Settings
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY
          CHECK (id = 1),
        language TEXT NOT NULL
          CHECK (language IN ('vi', 'en'))
      )
    ''');

    // Default language: Vietnamese
    await db.insert('app_settings', {'id': 1, 'language': 'vi'});

    // Indexes
    await db.execute('''
      CREATE INDEX idx_assignments_subject_code
      ON assignments(subject_code)
    ''');

    await db.execute('''
      CREATE INDEX idx_assignments_deadline
      ON assignments(deadline)
    ''');

    await db.execute('''
      CREATE INDEX idx_schedules_subject_code
      ON schedules(subject_code)
    ''');

    await db.execute('''
      CREATE INDEX idx_schedules_weekday
      ON schedules(weekday)
    ''');

    await db.execute('''
      CREATE INDEX idx_reminders_assignment_id
      ON reminders(assignment_id)
    ''');
  }

  // Close database connection.
  Future<void> closeDatabase() async {
    final currentFuture = _databaseFuture;

    if (currentFuture == null) {
      return;
    }

    final db = await currentFuture;
    await db.close();

    _database = null;
    _databaseFuture = null;
  }
}
