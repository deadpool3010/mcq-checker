import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../models/mcq_answer.dart';
import '../models/student_response.dart';
import '../models/class_report.dart';
import 'ai_service.dart';
import 'excel_service.dart';
import 'n8n_service.dart';
import 'database_service.dart';

class MCQService {
  final AIService _aiService;
  final ExcelService _excelService;
  final N8NService _n8nService;
  final DatabaseService _databaseService;
  final Uuid _uuid;

  MCQService({
    String n8nBaseUrl = 'https://demo.n8n.io', // Default N8N URL
    String? n8nApiKey,
  }) : _aiService = AIService(), // No API key needed now
       _excelService = ExcelService(),
       _n8nService = N8NService(baseUrl: n8nBaseUrl, apiKey: n8nApiKey),
       _databaseService = DatabaseService(),
       _uuid = const Uuid();

  /// Process answer key image and create exam
  Future<AnswerKey> processAnswerKey({
    required File imageFile,
    required String teacherId,
    required String examTitle,
    int expectedQuestions = 50,
    String answerFormat = 'A,B,C,D',
    Map<String, dynamic>? examMetadata,
  }) async {
    try {
      // Step 1: Extract answers using AI
      print('Extracting answers from answer key...');
      final extractedAnswers = await _aiService.extractAnswerKey(
        imageFile,
        expectedQuestions: expectedQuestions,
        answerFormat: answerFormat,
      );

      // Step 2: Create answer key object
      final answerKey = AnswerKey(
        id: _uuid.v4(),
        teacherId: teacherId,
        examTitle: examTitle,
        answers: extractedAnswers,
        imagePath: await _saveImageFile(imageFile, 'answer_key'),
        createdAt: DateTime.now(),
        examMetadata: examMetadata,
      );

      // Step 3: Save to database
      await _databaseService.saveAnswerKey(answerKey);

      // Step 4: Trigger N8N workflow
      await _n8nService.triggerAnswerKeyWorkflow(
        teacherId: teacherId,
        examTitle: examTitle,
        answerKeyPath: answerKey.imagePath,
        extractedAnswers: extractedAnswers,
        additionalData: examMetadata,
      );

      print('Answer key processed successfully: ${extractedAnswers.length} questions');
      return answerKey;
    } catch (e) {
      throw Exception('Failed to process answer key: $e');
    }
  }

  /// Process student answer sheets
  Future<List<StudentResult>> processStudentAnswers({
    required String examId,
    required List<File> studentImages,
    required List<String> studentNames,
    List<String>? studentIds,
    String answerFormat = 'A,B,C,D',
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // Get answer key
      final answerKey = await _databaseService.getAnswerKey(examId);
      if (answerKey == null) {
        throw Exception('Answer key not found for exam: $examId');
      }

      List<StudentResult> results = [];
      
      for (int i = 0; i < studentImages.length; i++) {
        final imageFile = studentImages[i];
        final studentName = i < studentNames.length ? studentNames[i] : 'Student ${i + 1}';
        final studentId = studentIds != null && i < studentIds.length 
            ? studentIds[i] 
            : 'STU_${_uuid.v4().substring(0, 8)}';

        onProgress?.call(i + 1, studentImages.length);

        try {
          print('Processing student: $studentName');
          
          // Extract student answers
          final studentResponses = await _aiService.extractStudentAnswers(
            imageFile,
            studentId,
            studentName,
            answerKey.answers,
            answerFormat: answerFormat,
          );

          // Calculate results
          final totalQuestions = answerKey.answers.length;
          final correctAnswers = studentResponses.where((r) => r.isCorrect).length;
          final percentage = (correctAnswers / totalQuestions) * 100;
          final grade = ExcelService.calculateGrade(percentage);

          // Create student result
          final studentResult = StudentResult(
            studentId: studentId,
            studentName: studentName,
            examId: examId,
            responses: studentResponses,
            imagePath: await _saveImageFile(imageFile, 'student_${studentId}'),
            submittedAt: DateTime.now(),
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
            percentage: percentage,
            grade: grade,
          );

          // Save to database
          await _databaseService.saveStudentResult(studentResult);
          results.add(studentResult);

        } catch (e) {
          print('Error processing student $studentName: $e');
          // Continue processing other students
        }
      }

      print('Processed ${results.length} student answer sheets');
      return results;
    } catch (e) {
      throw Exception('Failed to process student answers: $e');
    }
  }

  /// Generate comprehensive class report
  Future<ClassReport> generateClassReport({
    required String examId,
    bool generateExcel = true,
    bool generatePDF = false,
    bool triggerN8N = true,
  }) async {
    try {
      // Get answer key and student results
      final answerKey = await _databaseService.getAnswerKey(examId);
      if (answerKey == null) {
        throw Exception('Answer key not found for exam: $examId');
      }

      final studentResults = await _databaseService.getStudentResultsByExam(examId);
      if (studentResults.isEmpty) {
        throw Exception('No student results found for exam: $examId');
      }

      // Calculate statistics
      final statistics = _calculateClassStatistics(studentResults, answerKey.answers);

      // Create class report
      final classReport = ClassReport(
        id: _uuid.v4(),
        examId: examId,
        examTitle: answerKey.examTitle,
        teacherId: answerKey.teacherId,
        generatedAt: DateTime.now(),
        studentResults: studentResults,
        statistics: statistics,
      );

      String? excelFilePath;
      String? pdfFilePath;

      // Generate Excel report
      if (generateExcel) {
        print('Generating Excel report...');
        excelFilePath = await _excelService.generateClassReport(classReport);
        print('Excel report generated at: $excelFilePath');
      }

      // Generate PDF report (if implemented)
      if (generatePDF) {
        print('Generating PDF report...');
        // TODO: Implement PDF generation
      }

      // Update report with file paths
      final updatedReport = ClassReport(
        id: classReport.id,
        examId: classReport.examId,
        examTitle: classReport.examTitle,
        teacherId: classReport.teacherId,
        generatedAt: classReport.generatedAt,
        studentResults: classReport.studentResults,
        statistics: classReport.statistics,
        excelFilePath: excelFilePath,
        pdfFilePath: pdfFilePath,
      );

      // Save to database
      await _databaseService.saveClassReport(updatedReport);

      // Trigger N8N workflows
      if (triggerN8N) {
        // Student processing workflow
        await _n8nService.triggerStudentProcessingWorkflow(
          examId: examId,
          processedResults: studentResults,
          statistics: statistics,
        );

        // Report generation workflow
        if (excelFilePath != null) {
          await _n8nService.triggerReportGenerationWorkflow(
            classReport: updatedReport,
            excelFilePath: excelFilePath,
            pdfFilePath: pdfFilePath,
          );
        }

        // Quality check workflow
        await _n8nService.triggerQualityCheckWorkflow(
          examId: examId,
          answerKey: answerKey.answers,
          studentResults: studentResults,
        );

        // Grade alerts workflow
        await _n8nService.triggerGradeAlertWorkflow(
          studentResults: studentResults,
          examTitle: answerKey.examTitle,
        );
      }

      print('Class report generated successfully');
      return updatedReport;
    } catch (e) {
      throw Exception('Failed to generate class report: $e');
    }
  }

  /// Calculate class statistics
  ClassStatistics _calculateClassStatistics(
    List<StudentResult> studentResults, 
    List<MCQAnswer> answerKey
  ) {
    if (studentResults.isEmpty) {
      return ClassStatistics(
        totalStudents: 0,
        averageScore: 0,
        highestScore: 0,
        lowestScore: 0,
        passCount: 0,
        failCount: 0,
        gradeDistribution: {},
        questionAnalysis: {},
      );
    }

    final scores = studentResults.map((r) => r.percentage).toList();
    final totalStudents = studentResults.length;
    
    // Basic statistics
    final averageScore = scores.reduce((a, b) => a + b) / totalStudents;
    final highestScore = scores.reduce((a, b) => a > b ? a : b);
    final lowestScore = scores.reduce((a, b) => a < b ? a : b);
    
    // Pass/fail count (assuming 60% is passing)
    final passCount = scores.where((score) => score >= 60).length;
    final failCount = totalStudents - passCount;
    
    // Grade distribution
    Map<String, int> gradeDistribution = {};
    for (var result in studentResults) {
      gradeDistribution[result.grade] = (gradeDistribution[result.grade] ?? 0) + 1;
    }
    
    // Question analysis
    Map<String, double> questionAnalysis = {};
    for (var answer in answerKey) {
      final questionNum = answer.questionNumber;
      int correctCount = 0;
      
      for (var result in studentResults) {
        final response = result.responses.firstWhere(
          (r) => r.questionNumber == questionNum,
          orElse: () => StudentResponse(
            studentId: result.studentId,
            studentName: result.studentName,
            questionNumber: questionNum,
            selectedAnswer: '',
            isCorrect: false,
          ),
        );
        if (response.isCorrect) correctCount++;
      }
      
      questionAnalysis[questionNum] = (correctCount / totalStudents) * 100;
    }

    return ClassStatistics(
      totalStudents: totalStudents,
      averageScore: averageScore,
      highestScore: highestScore,
      lowestScore: lowestScore,
      passCount: passCount,
      failCount: failCount,
      gradeDistribution: gradeDistribution,
      questionAnalysis: questionAnalysis,
    );
  }

  /// Save image file to app directory
  Future<String> _saveImageFile(File imageFile, String prefix) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await imageFile.copy('${directory.path}/$fileName');
    return savedFile.path;
  }

  /// Get all exams for a teacher
  Future<List<AnswerKey>> getTeacherExams(String teacherId) async {
    return await _databaseService.getAnswerKeysByTeacher(teacherId);
  }

  /// Get exam results
  Future<List<StudentResult>> getExamResults(String examId) async {
    return await _databaseService.getStudentResultsByExam(examId);
  }

  /// Get class reports for a teacher
  Future<List<ClassReport>> getTeacherReports(String teacherId) async {
    return await _databaseService.getClassReportsByTeacher(teacherId);
  }

  /// Delete exam and all related data
  Future<void> deleteExam(String examId) async {
    // Delete student results
    final studentResults = await _databaseService.getStudentResultsByExam(examId);
    for (var result in studentResults) {
      await _databaseService.deleteStudentResult(result.studentId, examId);
    }

    // Delete class reports
    final classReports = await _databaseService.getClassReportsByTeacher(''); // Get all reports
    for (var report in classReports) {
      if (report.examId == examId) {
        await _databaseService.deleteClassReport(report.id);
      }
    }

    // Delete answer key
    await _databaseService.deleteAnswerKey(examId);
  }

  /// Generate individual student report
  Future<String> generateStudentReport(String studentId, String examId) async {
    final answerKey = await _databaseService.getAnswerKey(examId);
    final studentResult = await _databaseService.getStudentResult(studentId, examId);
    
    if (answerKey == null || studentResult == null) {
      throw Exception('Student result or answer key not found');
    }

    return await _excelService.generateStudentReport(studentResult, answerKey.answers);
  }

  /// Dispose resources
  void dispose() {
    _databaseService.close();
  }
}