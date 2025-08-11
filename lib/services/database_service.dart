import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/mcq_answer.dart';
import '../models/student_response.dart';
import '../models/class_report.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'mcq_checker.db';
  static const int _dbVersion = 1;

  // Table names
  static const String _answerKeysTable = 'answer_keys';
  static const String _studentResultsTable = 'student_results';
  static const String _classReportsTable = 'class_reports';
  static const String _settingsTable = 'settings';

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Answer Keys table
    await db.execute('''
      CREATE TABLE $_answerKeysTable (
        id TEXT PRIMARY KEY,
        teacher_id TEXT NOT NULL,
        exam_title TEXT NOT NULL,
        answers TEXT NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        exam_metadata TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Student Results table
    await db.execute('''
      CREATE TABLE $_studentResultsTable (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        exam_id TEXT NOT NULL,
        responses TEXT NOT NULL,
        image_path TEXT NOT NULL,
        submitted_at TEXT NOT NULL,
        total_questions INTEGER NOT NULL,
        correct_answers INTEGER NOT NULL,
        percentage REAL NOT NULL,
        grade TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (exam_id) REFERENCES $_answerKeysTable (id)
      )
    ''');

    // Class Reports table
    await db.execute('''
      CREATE TABLE $_classReportsTable (
        id TEXT PRIMARY KEY,
        exam_id TEXT NOT NULL,
        exam_title TEXT NOT NULL,
        teacher_id TEXT NOT NULL,
        generated_at TEXT NOT NULL,
        student_results TEXT NOT NULL,
        statistics TEXT NOT NULL,
        excel_file_path TEXT,
        pdf_file_path TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (exam_id) REFERENCES $_answerKeysTable (id)
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE $_settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_answer_keys_teacher ON $_answerKeysTable (teacher_id)');
    await db.execute('CREATE INDEX idx_student_results_exam ON $_studentResultsTable (exam_id)');
    await db.execute('CREATE INDEX idx_class_reports_teacher ON $_classReportsTable (teacher_id)');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic for future versions
    }
  }

  // ANSWER KEYS OPERATIONS

  /// Save answer key to database
  Future<int> saveAnswerKey(AnswerKey answerKey) async {
    final db = await database;
    return await db.insert(
      _answerKeysTable,
      {
        'id': answerKey.id,
        'teacher_id': answerKey.teacherId,
        'exam_title': answerKey.examTitle,
        'answers': jsonEncode(answerKey.answers.map((a) => a.toJson()).toList()),
        'image_path': answerKey.imagePath,
        'created_at': answerKey.createdAt.toIso8601String(),
        'exam_metadata': answerKey.examMetadata != null 
            ? jsonEncode(answerKey.examMetadata) 
            : null,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get answer key by ID
  Future<AnswerKey?> getAnswerKey(String id) async {
    final db = await database;
    final results = await db.query(
      _answerKeysTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return _answerKeyFromMap(results.first);
  }

  /// Get all answer keys for a teacher
  Future<List<AnswerKey>> getAnswerKeysByTeacher(String teacherId) async {
    final db = await database;
    final results = await db.query(
      _answerKeysTable,
      where: 'teacher_id = ?',
      whereArgs: [teacherId],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => _answerKeyFromMap(map)).toList();
  }

  /// Delete answer key
  Future<int> deleteAnswerKey(String id) async {
    final db = await database;
    return await db.delete(
      _answerKeysTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // STUDENT RESULTS OPERATIONS

  /// Save student result to database
  Future<int> saveStudentResult(StudentResult studentResult) async {
    final db = await database;
    return await db.insert(
      _studentResultsTable,
      {
        'id': '${studentResult.examId}_${studentResult.studentId}',
        'student_id': studentResult.studentId,
        'student_name': studentResult.studentName,
        'exam_id': studentResult.examId,
        'responses': jsonEncode(studentResult.responses.map((r) => r.toJson()).toList()),
        'image_path': studentResult.imagePath,
        'submitted_at': studentResult.submittedAt.toIso8601String(),
        'total_questions': studentResult.totalQuestions,
        'correct_answers': studentResult.correctAnswers,
        'percentage': studentResult.percentage,
        'grade': studentResult.grade,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get student results by exam ID
  Future<List<StudentResult>> getStudentResultsByExam(String examId) async {
    final db = await database;
    final results = await db.query(
      _studentResultsTable,
      where: 'exam_id = ?',
      whereArgs: [examId],
      orderBy: 'student_name ASC',
    );

    return results.map((map) => _studentResultFromMap(map)).toList();
  }

  /// Get student result by student ID and exam ID
  Future<StudentResult?> getStudentResult(String studentId, String examId) async {
    final db = await database;
    final results = await db.query(
      _studentResultsTable,
      where: 'student_id = ? AND exam_id = ?',
      whereArgs: [studentId, examId],
    );

    if (results.isEmpty) return null;
    return _studentResultFromMap(results.first);
  }

  /// Delete student result
  Future<int> deleteStudentResult(String studentId, String examId) async {
    final db = await database;
    return await db.delete(
      _studentResultsTable,
      where: 'student_id = ? AND exam_id = ?',
      whereArgs: [studentId, examId],
    );
  }

  // CLASS REPORTS OPERATIONS

  /// Save class report to database
  Future<int> saveClassReport(ClassReport classReport) async {
    final db = await database;
    return await db.insert(
      _classReportsTable,
      {
        'id': classReport.id,
        'exam_id': classReport.examId,
        'exam_title': classReport.examTitle,
        'teacher_id': classReport.teacherId,
        'generated_at': classReport.generatedAt.toIso8601String(),
        'student_results': jsonEncode(classReport.studentResults.map((r) => r.toJson()).toList()),
        'statistics': jsonEncode(classReport.statistics.toJson()),
        'excel_file_path': classReport.excelFilePath,
        'pdf_file_path': classReport.pdfFilePath,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get class report by ID
  Future<ClassReport?> getClassReport(String id) async {
    final db = await database;
    final results = await db.query(
      _classReportsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return _classReportFromMap(results.first);
  }

  /// Get all class reports for a teacher
  Future<List<ClassReport>> getClassReportsByTeacher(String teacherId) async {
    final db = await database;
    final results = await db.query(
      _classReportsTable,
      where: 'teacher_id = ?',
      whereArgs: [teacherId],
      orderBy: 'generated_at DESC',
    );

    return results.map((map) => _classReportFromMap(map)).toList();
  }

  /// Delete class report
  Future<int> deleteClassReport(String id) async {
    final db = await database;
    return await db.delete(
      _classReportsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // SETTINGS OPERATIONS

  /// Save setting
  Future<int> saveSetting(String key, String value) async {
    final db = await database;
    return await db.insert(
      _settingsTable,
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get setting
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      _settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  /// Get all settings
  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final results = await db.query(_settingsTable);
    
    Map<String, String> settings = {};
    for (var result in results) {
      settings[result['key'] as String] = result['value'] as String;
    }
    return settings;
  }

  // SYNC OPERATIONS

  /// Mark item as synced
  Future<int> markAsSynced(String table, String id) async {
    final db = await database;
    return await db.update(
      table,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get unsynced items
  Future<List<Map<String, dynamic>>> getUnsyncedItems(String table) async {
    final db = await database;
    return await db.query(
      table,
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  // UTILITY METHODS

  /// Convert map to AnswerKey
  AnswerKey _answerKeyFromMap(Map<String, dynamic> map) {
    final answersJson = jsonDecode(map['answers'] as String) as List;
    final answers = answersJson.map((a) => MCQAnswer.fromJson(a)).toList();

    return AnswerKey(
      id: map['id'] as String,
      teacherId: map['teacher_id'] as String,
      examTitle: map['exam_title'] as String,
      answers: answers,
      imagePath: map['image_path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      examMetadata: map['exam_metadata'] != null 
          ? jsonDecode(map['exam_metadata'] as String)
          : null,
    );
  }

  /// Convert map to StudentResult
  StudentResult _studentResultFromMap(Map<String, dynamic> map) {
    final responsesJson = jsonDecode(map['responses'] as String) as List;
    final responses = responsesJson.map((r) => StudentResponse.fromJson(r)).toList();

    return StudentResult(
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      examId: map['exam_id'] as String,
      responses: responses,
      imagePath: map['image_path'] as String,
      submittedAt: DateTime.parse(map['submitted_at'] as String),
      totalQuestions: map['total_questions'] as int,
      correctAnswers: map['correct_answers'] as int,
      percentage: map['percentage'] as double,
      grade: map['grade'] as String,
    );
  }

  /// Convert map to ClassReport
  ClassReport _classReportFromMap(Map<String, dynamic> map) {
    final studentResultsJson = jsonDecode(map['student_results'] as String) as List;
    final studentResults = studentResultsJson.map((r) => StudentResult.fromJson(r)).toList();
    
    final statistics = ClassStatistics.fromJson(
      jsonDecode(map['statistics'] as String)
    );

    return ClassReport(
      id: map['id'] as String,
      examId: map['exam_id'] as String,
      examTitle: map['exam_title'] as String,
      teacherId: map['teacher_id'] as String,
      generatedAt: DateTime.parse(map['generated_at'] as String),
      studentResults: studentResults,
      statistics: statistics,
      excelFilePath: map['excel_file_path'] as String?,
      pdfFilePath: map['pdf_file_path'] as String?,
    );
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_answerKeysTable);
    await db.delete(_studentResultsTable);
    await db.delete(_classReportsTable);
    await db.delete(_settingsTable);
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}