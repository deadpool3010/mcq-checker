import 'student_response.dart';

class ClassStatistics {
  final int totalStudents;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final int passCount;
  final int failCount;
  final Map<String, int> gradeDistribution;
  final Map<String, double> questionAnalysis; // question number -> percentage correct

  ClassStatistics({
    required this.totalStudents,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.passCount,
    required this.failCount,
    required this.gradeDistribution,
    required this.questionAnalysis,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalStudents': totalStudents,
      'averageScore': averageScore,
      'highestScore': highestScore,
      'lowestScore': lowestScore,
      'passCount': passCount,
      'failCount': failCount,
      'gradeDistribution': gradeDistribution,
      'questionAnalysis': questionAnalysis,
    };
  }

  factory ClassStatistics.fromJson(Map<String, dynamic> json) {
    return ClassStatistics(
      totalStudents: json['totalStudents'],
      averageScore: json['averageScore'],
      highestScore: json['highestScore'],
      lowestScore: json['lowestScore'],
      passCount: json['passCount'],
      failCount: json['failCount'],
      gradeDistribution: Map<String, int>.from(json['gradeDistribution']),
      questionAnalysis: Map<String, double>.from(json['questionAnalysis']),
    );
  }
}

class ClassReport {
  final String id;
  final String examId;
  final String examTitle;
  final String teacherId;
  final DateTime generatedAt;
  final List<StudentResult> studentResults;
  final ClassStatistics statistics;
  final String? excelFilePath;
  final String? pdfFilePath;

  ClassReport({
    required this.id,
    required this.examId,
    required this.examTitle,
    required this.teacherId,
    required this.generatedAt,
    required this.studentResults,
    required this.statistics,
    this.excelFilePath,
    this.pdfFilePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examId': examId,
      'examTitle': examTitle,
      'teacherId': teacherId,
      'generatedAt': generatedAt.toIso8601String(),
      'studentResults': studentResults.map((s) => s.toJson()).toList(),
      'statistics': statistics.toJson(),
      'excelFilePath': excelFilePath,
      'pdfFilePath': pdfFilePath,
    };
  }

  factory ClassReport.fromJson(Map<String, dynamic> json) {
    return ClassReport(
      id: json['id'],
      examId: json['examId'],
      examTitle: json['examTitle'],
      teacherId: json['teacherId'],
      generatedAt: DateTime.parse(json['generatedAt']),
      studentResults: (json['studentResults'] as List)
          .map((s) => StudentResult.fromJson(s))
          .toList(),
      statistics: ClassStatistics.fromJson(json['statistics']),
      excelFilePath: json['excelFilePath'],
      pdfFilePath: json['pdfFilePath'],
    );
  }
}