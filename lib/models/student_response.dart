class StudentResponse {
  final String studentId;
  final String studentName;
  final String questionNumber;
  final String selectedAnswer;
  final double confidence;
  final bool isCorrect;
  final Map<String, dynamic>? metadata;

  StudentResponse({
    required this.studentId,
    required this.studentName,
    required this.questionNumber,
    required this.selectedAnswer,
    this.confidence = 1.0,
    required this.isCorrect,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'questionNumber': questionNumber,
      'selectedAnswer': selectedAnswer,
      'confidence': confidence,
      'isCorrect': isCorrect,
      'metadata': metadata,
    };
  }

  factory StudentResponse.fromJson(Map<String, dynamic> json) {
    return StudentResponse(
      studentId: json['studentId'],
      studentName: json['studentName'],
      questionNumber: json['questionNumber'],
      selectedAnswer: json['selectedAnswer'],
      confidence: json['confidence'] ?? 1.0,
      isCorrect: json['isCorrect'],
      metadata: json['metadata'],
    );
  }
}

class StudentResult {
  final String studentId;
  final String studentName;
  final String examId;
  final List<StudentResponse> responses;
  final String imagePath;
  final DateTime submittedAt;
  final int totalQuestions;
  final int correctAnswers;
  final double percentage;
  final String grade;

  StudentResult({
    required this.studentId,
    required this.studentName,
    required this.examId,
    required this.responses,
    required this.imagePath,
    required this.submittedAt,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
    required this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'examId': examId,
      'responses': responses.map((r) => r.toJson()).toList(),
      'imagePath': imagePath,
      'submittedAt': submittedAt.toIso8601String(),
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'percentage': percentage,
      'grade': grade,
    };
  }

  factory StudentResult.fromJson(Map<String, dynamic> json) {
    return StudentResult(
      studentId: json['studentId'],
      studentName: json['studentName'],
      examId: json['examId'],
      responses: (json['responses'] as List)
          .map((r) => StudentResponse.fromJson(r))
          .toList(),
      imagePath: json['imagePath'],
      submittedAt: DateTime.parse(json['submittedAt']),
      totalQuestions: json['totalQuestions'],
      correctAnswers: json['correctAnswers'],
      percentage: json['percentage'],
      grade: json['grade'],
    );
  }
}