import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/class_report.dart';
import '../models/student_response.dart';
import '../models/mcq_answer.dart';

class ExcelService {
  /// Generate comprehensive Excel report for class results
  Future<String> generateClassReport(ClassReport classReport) async {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create multiple sheets
    await _createSummarySheet(excel, classReport);
    await _createDetailedResultsSheet(excel, classReport);
    await _createStatisticsSheet(excel, classReport);
    await _createQuestionAnalysisSheet(excel, classReport);
    
    // Save file
    return await _saveExcelFile(excel, classReport.examTitle);
  }

  /// Create summary sheet with key metrics
  Future<void> _createSummarySheet(Excel excel, ClassReport report) async {
    final sheet = excel['Summary'];
    
    // Title and header
    var cell = sheet.cell(CellIndex.indexByString('A1'));
    cell.value = TextCellValue('MCQ Exam Results Summary');
    
    // Exam details
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Exam Title:');
    sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(report.examTitle);
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Generated On:');
    sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(
        DateFormat('yyyy-MM-dd HH:mm').format(report.generatedAt));
    
    // Statistics
    final stats = report.statistics;
    int row = 6;
    
    final summaryData = [
      ['Total Students', stats.totalStudents.toString()],
      ['Average Score', '${stats.averageScore.toStringAsFixed(1)}%'],
      ['Highest Score', '${stats.highestScore.toStringAsFixed(1)}%'],
      ['Lowest Score', '${stats.lowestScore.toStringAsFixed(1)}%'],
      ['Students Passed', stats.passCount.toString()],
      ['Students Failed', stats.failCount.toString()],
      ['Pass Rate', '${((stats.passCount / stats.totalStudents) * 100).toStringAsFixed(1)}%'],
    ];
    
    for (var data in summaryData) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(data[0]);
      sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(data[1]);
      row++;
    }
    
    // Grade distribution
    row += 2;
    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Grade Distribution');
    row++;
    
    stats.gradeDistribution.forEach((grade, count) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Grade $grade');
      sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(count);
      sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(
          '${((count / stats.totalStudents) * 100).toStringAsFixed(1)}%');
      row++;
    });
  }

  /// Create detailed results sheet with all student scores
  Future<void> _createDetailedResultsSheet(Excel excel, ClassReport report) async {
    final sheet = excel['Detailed Results'];
    
    // Headers
    final headers = [
      'Student ID',
      'Student Name', 
      'Total Questions',
      'Correct Answers',
      'Wrong Answers',
      'Score (%)',
      'Grade',
      'Submitted At'
    ];
    
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
    }
    
    // Student data
    for (int i = 0; i < report.studentResults.length; i++) {
      final student = report.studentResults[i];
      final row = i + 1;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = 
          TextCellValue(student.studentId);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = 
          TextCellValue(student.studentName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = 
          IntCellValue(student.totalQuestions);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = 
          IntCellValue(student.correctAnswers);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = 
          IntCellValue(student.totalQuestions - student.correctAnswers);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = 
          TextCellValue(student.percentage.toStringAsFixed(1));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = 
          TextCellValue(student.grade);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = 
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(student.submittedAt));
    }
  }

  /// Create statistics sheet with charts and analysis
  Future<void> _createStatisticsSheet(Excel excel, ClassReport report) async {
    final sheet = excel['Statistics'];
    final stats = report.statistics;
    
    // Performance distribution
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Performance Analysis');
    
    // Score ranges
    Map<String, int> scoreRanges = {
      '90-100%': 0,
      '80-89%': 0,
      '70-79%': 0,
      '60-69%': 0,
      '50-59%': 0,
      'Below 50%': 0,
    };
    
    for (var student in report.studentResults) {
      if (student.percentage >= 90) scoreRanges['90-100%'] = scoreRanges['90-100%']! + 1;
      else if (student.percentage >= 80) scoreRanges['80-89%'] = scoreRanges['80-89%']! + 1;
      else if (student.percentage >= 70) scoreRanges['70-79%'] = scoreRanges['70-79%']! + 1;
      else if (student.percentage >= 60) scoreRanges['60-69%'] = scoreRanges['60-69%']! + 1;
      else if (student.percentage >= 50) scoreRanges['50-59%'] = scoreRanges['50-59%']! + 1;
      else scoreRanges['Below 50%'] = scoreRanges['Below 50%']! + 1;
    }
    
    int row = 3;
    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Score Range');
    sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue('Students');
    sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue('Percentage');
    row++;
    
    scoreRanges.forEach((range, count) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(range);
      sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(count);
      sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(
          '${((count / stats.totalStudents) * 100).toStringAsFixed(1)}%');
      row++;
    });
  }

  /// Create question analysis sheet
  Future<void> _createQuestionAnalysisSheet(Excel excel, ClassReport report) async {
    final sheet = excel['Question Analysis'];
    
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Question-wise Analysis');
    
    // Headers
    final headers = ['Question', 'Correct %', 'Difficulty Level'];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
      cell.value = TextCellValue(headers[i]);
    }
    
    int row = 3;
    report.statistics.questionAnalysis.forEach((questionNum, correctPercentage) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = 
          TextCellValue('Q$questionNum');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = 
          TextCellValue('${correctPercentage.toStringAsFixed(1)}%');
      
      String difficulty;
      if (correctPercentage >= 80) {
        difficulty = 'Easy';
      } else if (correctPercentage >= 60) {
        difficulty = 'Medium';
      } else {
        difficulty = 'Hard';
      }
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = 
          TextCellValue(difficulty);
      
      row++;
    });
  }

  /// Generate individual student report
  Future<String> generateStudentReport(StudentResult studentResult, List<MCQAnswer> answerKey) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    
    final sheet = excel['Student Report'];
    
    // Student info
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Student Report');
    
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Student Name:');
    sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(studentResult.studentName);
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Student ID:');
    sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(studentResult.studentId);
    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Score:');
    sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue('${studentResult.percentage}%');
    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Grade:');
    sheet.cell(CellIndex.indexByString('B6')).value = TextCellValue(studentResult.grade);
    
    // Question-wise breakdown
    final headers = ['Question', 'Correct Answer', 'Student Answer', 'Result'];
    int headerRow = 8;
    
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: headerRow));
      cell.value = TextCellValue(headers[i]);
    }
    
    // Create answer key map for lookup
    Map<String, String> correctAnswers = {};
    for (var answer in answerKey) {
      correctAnswers[answer.questionNumber] = answer.correctAnswer;
    }
    
    int row = headerRow + 1;
    for (var response in studentResult.responses) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = 
          TextCellValue(response.questionNumber);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = 
          TextCellValue(correctAnswers[response.questionNumber] ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = 
          TextCellValue(response.selectedAnswer);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = 
          TextCellValue(response.isCorrect ? 'Correct' : 'Wrong');
      
      row++;
    }
    
    return await _saveExcelFile(excel, '${studentResult.studentName}_Report');
  }

  /// Save Excel file and return path
  Future<String> _saveExcelFile(Excel excel, String fileName) async {
    try {
      // Try to save to Downloads folder (Android) or Documents (iOS)
      Directory? directory;
      
      if (Platform.isAndroid) {
        // For Android, try to save to Downloads
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage
          directory = await getExternalStorageDirectory();
        }
      } else {
        // For iOS, use Documents directory
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        throw Exception('Could not access storage directory');
      }
      
      // Create a clean filename
      final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/${cleanFileName}_$timestamp.xlsx';
      
      print('Saving Excel file to: $filePath');
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      
      // Verify file was created
      if (await file.exists()) {
        final fileSize = await file.length();
        print('Excel file saved successfully: $filePath (${fileSize} bytes)');
        return filePath;
      } else {
        throw Exception('File was not created successfully');
      }
    } catch (e) {
      print('Error saving Excel file: $e');
      
      // Fallback to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/${cleanFileName}_$timestamp.xlsx';
      
      print('Fallback: Saving to app directory: $filePath');
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      
      return filePath;
    }
  }

  /// Share Excel file with user
  Future<void> shareExcelFile(String filePath, String examTitle) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'MCQ Exam Report: $examTitle',
          subject: 'Exam Report - $examTitle',
        );
      } else {
        throw Exception('File not found: $filePath');
      }
    } catch (e) {
      print('Error sharing file: $e');
      rethrow;
    }
  }

  /// Get user-friendly file location message
  String getFileLocationMessage(String filePath) {
    if (Platform.isAndroid) {
      if (filePath.contains('/Download')) {
        return 'File saved to Downloads folder';
      } else if (filePath.contains('/storage/emulated/0')) {
        return 'File saved to device storage';
      }
    }
    return 'File saved: ${filePath.split('/').last}';
  }

  /// Calculate grade based on percentage
  static String calculateGrade(double percentage) {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }
}