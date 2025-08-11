import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/class_report.dart';
import '../models/student_response.dart';
import '../models/mcq_answer.dart';

class N8NService {
  final String baseUrl;
  final String? apiKey;
  final Map<String, String> _headers;

  N8NService({
    required this.baseUrl,
    this.apiKey,
  }) : _headers = {
    'Content-Type': 'application/json',
    if (apiKey != null) 'Authorization': 'Bearer $apiKey',
  };

  /// Trigger N8N workflow when answer key is uploaded
  Future<Map<String, dynamic>> triggerAnswerKeyWorkflow({
    required String teacherId,
    required String examTitle,
    required String answerKeyPath,
    required List<MCQAnswer> extractedAnswers,
    Map<String, dynamic>? additionalData,
  }) async {
    final payload = {
      'event': 'answer_key_uploaded',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'teacherId': teacherId,
        'examTitle': examTitle,
        'answerKeyPath': answerKeyPath,
        'totalQuestions': extractedAnswers.length,
        'extractedAnswers': extractedAnswers.map((a) => a.toJson()).toList(),
        'metadata': additionalData ?? {},
      }
    };

    return await _sendWebhook('/webhook/answer-key-uploaded', payload);
  }

  /// Trigger N8N workflow when student answers are processed
  Future<Map<String, dynamic>> triggerStudentProcessingWorkflow({
    required String examId,
    required List<StudentResult> processedResults,
    required ClassStatistics statistics,
    Map<String, dynamic>? additionalData,
  }) async {
    final payload = {
      'event': 'student_answers_processed',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'examId': examId,
        'totalStudents': processedResults.length,
        'averageScore': statistics.averageScore,
        'passRate': (statistics.passCount / statistics.totalStudents) * 100,
        'processedResults': processedResults.map((r) => r.toJson()).toList(),
        'statistics': statistics.toJson(),
        'metadata': additionalData ?? {},
      }
    };

    return await _sendWebhook('/webhook/student-answers-processed', payload);
  }

  /// Trigger N8N workflow when class report is generated
  Future<Map<String, dynamic>> triggerReportGenerationWorkflow({
    required ClassReport classReport,
    required String excelFilePath,
    String? pdfFilePath,
    Map<String, dynamic>? additionalData,
  }) async {
    final payload = {
      'event': 'class_report_generated',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'reportId': classReport.id,
        'examId': classReport.examId,
        'examTitle': classReport.examTitle,
        'teacherId': classReport.teacherId,
        'totalStudents': classReport.statistics.totalStudents,
        'averageScore': classReport.statistics.averageScore,
        'excelFilePath': excelFilePath,
        'pdfFilePath': pdfFilePath,
        'statistics': classReport.statistics.toJson(),
        'metadata': additionalData ?? {},
      }
    };

    return await _sendWebhook('/webhook/class-report-generated', payload);
  }

  /// Send notification workflow (email, SMS, etc.)
  Future<Map<String, dynamic>> triggerNotificationWorkflow({
    required String notificationType, // 'email', 'sms', 'push'
    required String recipient,
    required String subject,
    required String message,
    Map<String, dynamic>? attachments,
    Map<String, dynamic>? additionalData,
  }) async {
    final payload = {
      'event': 'send_notification',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'type': notificationType,
        'recipient': recipient,
        'subject': subject,
        'message': message,
        'attachments': attachments ?? {},
        'metadata': additionalData ?? {},
      }
    };

    return await _sendWebhook('/webhook/send-notification', payload);
  }

  /// Trigger backup workflow for cloud storage
  Future<Map<String, dynamic>> triggerBackupWorkflow({
    required String dataType, // 'answer_key', 'student_results', 'reports'
    required String filePath,
    required Map<String, dynamic> metadata,
  }) async {
    final payload = {
      'event': 'backup_data',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'dataType': dataType,
        'filePath': filePath,
        'metadata': metadata,
      }
    };

    return await _sendWebhook('/webhook/backup-data', payload);
  }

  /// Trigger analytics workflow for performance tracking
  Future<Map<String, dynamic>> triggerAnalyticsWorkflow({
    required String eventType,
    required Map<String, dynamic> analyticsData,
  }) async {
    final payload = {
      'event': 'analytics_event',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'eventType': eventType,
        'analytics': analyticsData,
      }
    };

    return await _sendWebhook('/webhook/analytics-event', payload);
  }

  /// Send grade alerts to students/parents
  Future<Map<String, dynamic>> triggerGradeAlertWorkflow({
    required List<StudentResult> studentResults,
    required String examTitle,
    Map<String, dynamic>? alertSettings,
  }) async {
    final payload = {
      'event': 'grade_alerts',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'examTitle': examTitle,
        'studentResults': studentResults.map((r) => {
          'studentId': r.studentId,
          'studentName': r.studentName,
          'percentage': r.percentage,
          'grade': r.grade,
          'totalQuestions': r.totalQuestions,
          'correctAnswers': r.correctAnswers,
        }).toList(),
        'alertSettings': alertSettings ?? {},
      }
    };

    return await _sendWebhook('/webhook/grade-alerts', payload);
  }

  /// Trigger workflow for quality assurance checks
  Future<Map<String, dynamic>> triggerQualityCheckWorkflow({
    required String examId,
    required List<MCQAnswer> answerKey,
    required List<StudentResult> studentResults,
    Map<String, dynamic>? qualityMetrics,
  }) async {
    // Calculate quality metrics
    final lowConfidenceAnswers = answerKey.where((a) => a.confidence < 0.8).toList();
    final suspiciousResults = studentResults.where((r) => 
      r.responses.any((resp) => resp.confidence < 0.7)).toList();

    final payload = {
      'event': 'quality_check',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'examId': examId,
        'totalQuestions': answerKey.length,
        'lowConfidenceAnswers': lowConfidenceAnswers.length,
        'suspiciousResults': suspiciousResults.length,
        'qualityScore': _calculateQualityScore(answerKey, studentResults),
        'details': {
          'lowConfidenceAnswers': lowConfidenceAnswers.map((a) => a.toJson()).toList(),
          'suspiciousResults': suspiciousResults.map((r) => {
            'studentId': r.studentId,
            'studentName': r.studentName,
            'lowConfidenceCount': r.responses.where((resp) => resp.confidence < 0.7).length,
          }).toList(),
        },
        'qualityMetrics': qualityMetrics ?? {},
      }
    };

    return await _sendWebhook('/webhook/quality-check', payload);
  }

  /// Generic webhook sender
  Future<Map<String, dynamic>> _sendWebhook(String endpoint, Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'response': response.body.isNotEmpty ? jsonDecode(response.body) : {},
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': response.body,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Upload file to N8N for processing
  Future<Map<String, dynamic>> uploadFileToN8N({
    required String filePath,
    required String endpoint,
    Map<String, String>? additionalFields,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      
      // Add headers
      request.headers.addAll(_headers);
      
      // Add file
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'response': response.body.isNotEmpty ? jsonDecode(response.body) : {},
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': response.body,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Calculate quality score based on confidence levels
  double _calculateQualityScore(List<MCQAnswer> answerKey, List<StudentResult> studentResults) {
    double totalConfidence = 0;
    int totalItems = 0;

    // Answer key confidence
    for (var answer in answerKey) {
      totalConfidence += answer.confidence;
      totalItems++;
    }

    // Student responses confidence
    for (var result in studentResults) {
      for (var response in result.responses) {
        totalConfidence += response.confidence;
        totalItems++;
      }
    }

    return totalItems > 0 ? (totalConfidence / totalItems) * 100 : 0;
  }

  /// Get N8N workflow status
  Future<Map<String, dynamic>> getWorkflowStatus(String workflowId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/workflows/$workflowId/executions'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': response.body,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}