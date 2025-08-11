import 'dart:io';
import 'package:flutter/material.dart';
import '../models/mcq_answer.dart';
import '../models/student_response.dart';
import '../models/class_report.dart';
import '../services/mcq_service.dart';

class MCQProvider with ChangeNotifier {
  MCQService? _mcqService;
  
  // Current state
  AnswerKey? _currentAnswerKey;
  List<StudentResult> _studentResults = [];
  ClassReport? _currentClassReport;
  bool _isProcessing = false;
  String? _error;
  double _progress = 0.0;
  String _progressMessage = '';
  
  // Teacher data
  String _teacherId = 'teacher_001'; // Default teacher ID
  List<AnswerKey> _teacherExams = [];
  List<ClassReport> _teacherReports = [];
  
  // Settings
  Map<String, String> _settings = {};

  // Getters
  AnswerKey? get currentAnswerKey => _currentAnswerKey;
  List<StudentResult> get studentResults => _studentResults;
  ClassReport? get currentClassReport => _currentClassReport;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  double get progress => _progress;
  String get progressMessage => _progressMessage;
  String get teacherId => _teacherId;
  List<AnswerKey> get teacherExams => _teacherExams;
  List<ClassReport> get teacherReports => _teacherReports;
  Map<String, String> get settings => _settings;
  bool get isInitialized => _mcqService != null;

  /// Initialize the MCQ service automatically
  Future<void> initializeService({
    String n8nBaseUrl = 'https://demo.n8n.io',
    String? n8nApiKey,
  }) async {
    try {
      _mcqService = MCQService(
        n8nBaseUrl: n8nBaseUrl,
        n8nApiKey: n8nApiKey,
      );
      await _loadTeacherData();
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize service: $e');
    }
  }

  /// Auto-initialize service on provider creation
  void autoInitialize() {
    if (_mcqService == null) {
      print('🔧 Starting autoInitialize...');
      try {
        // Initialize synchronously
        _mcqService = MCQService();
        print('✅ MCQService created - isInitialized: $isInitialized');
        
        // Notify listeners that the service is now initialized
        notifyListeners();
        print('📢 Listeners notified');
        
        
      } catch (e) {
        print('❌ Error in autoInitialize: $e');
        _setError('Failed to auto-initialize: $e');
      }
    } else {
      print('⚠️ MCQService already exists - isInitialized: $isInitialized');
    }
  }




  /// Process answer key image
  Future<void> processAnswerKey({
    required File imageFile,
    required String examTitle,
    int expectedQuestions = 50,
    String answerFormat = 'A,B,C,D',
    Map<String, dynamic>? examMetadata,
  }) async {
    // Ensure service is initialized
    if (_mcqService == null) {
      autoInitialize();
    }
    
    if (_mcqService == null) {
      _setError('Failed to initialize service');
      return;
    }

    _setProcessing(true, 'Processing answer key...');
    _clearError();

    try {
      print('Starting answer key processing...');
      print('Image file path: ${imageFile.path}');
      print('Exam title: $examTitle');
      
      _currentAnswerKey = await _mcqService!.processAnswerKey(
        imageFile: imageFile,
        teacherId: _teacherId,
        examTitle: examTitle,
        expectedQuestions: expectedQuestions,
        answerFormat: answerFormat,
        examMetadata: examMetadata,
      );
      
      print('Answer key processed successfully');
      await _loadTeacherData();
      _setProgress(1.0, 'Answer key processed successfully!');
    } catch (e, stackTrace) {
      print('Error processing answer key: $e');
      print('Stack trace: $stackTrace');
      _setError('Failed to process answer key: $e');
    } finally {
      _setProcessing(false);
    }
  }

  /// Process student answer sheets
  Future<void> processStudentAnswers({
    required String examId,
    required List<File> studentImages,
    required List<String> studentNames,
    List<String>? studentIds,
    String answerFormat = 'A,B,C,D',
  }) async {
    if (_mcqService == null) {
      _setError('Service not initialized');
      return;
    }

    _setProcessing(true, 'Processing student answers...');
    _clearError();
    _setProgress(0.0, 'Starting to process student answers...');

    try {
      _studentResults = await _mcqService!.processStudentAnswers(
        examId: examId,
        studentImages: studentImages,
        studentNames: studentNames,
        studentIds: studentIds,
        answerFormat: answerFormat,
        onProgress: (current, total) {
          final progress = current / total;
          _setProgress(progress, 'Processing student $current of $total...');
        },
      );

      _setProgress(1.0, 'All student answers processed successfully!');
    } catch (e) {
      _setError('Failed to process student answers: $e');
    } finally {
      _setProcessing(false);
    }
  }

  /// Generate class report
  Future<void> generateClassReport({
    required String examId,
    bool generateExcel = true,
    bool generatePDF = false,
    bool triggerN8N = true,
  }) async {
    if (_mcqService == null) {
      _setError('Service not initialized');
      return;
    }

    _setProcessing(true, 'Generating class report...');
    _clearError();

    try {
      _currentClassReport = await _mcqService!.generateClassReport(
        examId: examId,
        generateExcel: generateExcel,
        generatePDF: generatePDF,
        triggerN8N: triggerN8N,
      );

      await _loadTeacherData();
      _setProgress(1.0, 'Class report generated successfully!');
    } catch (e) {
      _setError('Failed to generate class report: $e');
    } finally {
      _setProcessing(false);
    }
  }

  /// Load teacher's exams and reports
  Future<void> _loadTeacherData() async {
    if (_mcqService == null) return;

    try {
      _teacherExams = await _mcqService!.getTeacherExams(_teacherId);
      _teacherReports = await _mcqService!.getTeacherReports(_teacherId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load teacher data: $e');
    }
  }

  /// Load exam results
  Future<void> loadExamResults(String examId) async {
    if (_mcqService == null) return;

    try {
      _studentResults = await _mcqService!.getExamResults(examId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load exam results: $e');
    }
  }

  /// Delete exam
  Future<void> deleteExam(String examId) async {
    if (_mcqService == null) return;

    try {
      await _mcqService!.deleteExam(examId);
      await _loadTeacherData();
      
      // Clear current data if it was deleted
      if (_currentAnswerKey?.id == examId) {
        _currentAnswerKey = null;
        _studentResults.clear();
        _currentClassReport = null;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete exam: $e');
    }
  }

  /// Generate individual student report
  Future<String?> generateStudentReport(String studentId, String examId) async {
    if (_mcqService == null) return null;

    try {
      return await _mcqService!.generateStudentReport(studentId, examId);
    } catch (e) {
      _setError('Failed to generate student report: $e');
      return null;
    }
  }

  /// Set current exam
  void setCurrentExam(AnswerKey answerKey) {
    _currentAnswerKey = answerKey;
    _studentResults.clear();
    _currentClassReport = null;
    notifyListeners();
  }

  /// Clear current data
  void clearCurrentData() {
    _currentAnswerKey = null;
    _studentResults.clear();
    _currentClassReport = null;
    _clearError();
    notifyListeners();
  }

  /// Update teacher ID
  void setTeacherId(String teacherId) {
    _teacherId = teacherId;
    _loadTeacherData();
  }

  /// Helper methods
  void _setProcessing(bool processing, [String message = '']) {
    _isProcessing = processing;
    _progressMessage = message;
    if (!processing) {
      _progress = 0.0;
    }
    notifyListeners();
  }

  void _setProgress(double progress, String message) {
    _progress = progress.clamp(0.0, 1.0);
    _progressMessage = message;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isProcessing = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Clear error (public method)
  void clearError() {
    _clearError();
  }

  /// Refresh data
  Future<void> refresh() async {
    await _loadTeacherData();
  }

  /// Get exam statistics
  Map<String, dynamic> getExamStatistics(String examId) {
    final results = _studentResults.where((r) => r.examId == examId).toList();
    if (results.isEmpty) return {};

    final scores = results.map((r) => r.percentage).toList();
    final totalStudents = results.length;
    final averageScore = scores.reduce((a, b) => a + b) / totalStudents;
    final highestScore = scores.reduce((a, b) => a > b ? a : b);
    final lowestScore = scores.reduce((a, b) => a < b ? a : b);
    final passCount = scores.where((score) => score >= 60).length;

    return {
      'totalStudents': totalStudents,
      'averageScore': averageScore,
      'highestScore': highestScore,
      'lowestScore': lowestScore,
      'passCount': passCount,
      'failCount': totalStudents - passCount,
      'passRate': (passCount / totalStudents) * 100,
    };
  }

  @override
  void dispose() {
    _mcqService?.dispose();
    super.dispose();
  }
}