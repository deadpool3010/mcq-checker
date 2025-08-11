class MCQAnswer {
  final String questionNumber;
  final String correctAnswer;
  final double confidence;
  final Map<String, dynamic>? metadata;

  MCQAnswer({
    required this.questionNumber,
    required this.correctAnswer,
    this.confidence = 1.0,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionNumber': questionNumber,
      'correctAnswer': correctAnswer,
      'confidence': confidence,
      'metadata': metadata,
    };
  }

  factory MCQAnswer.fromJson(Map<String, dynamic> json) {
    return MCQAnswer(
      questionNumber: json['questionNumber'],
      correctAnswer: json['correctAnswer'],
      confidence: json['confidence'] ?? 1.0,
      metadata: json['metadata'],
    );
  }
}

class AnswerKey {
  final String id;
  final String teacherId;
  final String examTitle;
  final List<MCQAnswer> answers;
  final String imagePath;
  final DateTime createdAt;
  final Map<String, dynamic>? examMetadata;

  AnswerKey({
    required this.id,
    required this.teacherId,
    required this.examTitle,
    required this.answers,
    required this.imagePath,
    required this.createdAt,
    this.examMetadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'examTitle': examTitle,
      'answers': answers.map((a) => a.toJson()).toList(),
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'examMetadata': examMetadata,
    };
  }

  factory AnswerKey.fromJson(Map<String, dynamic> json) {
    return AnswerKey(
      id: json['id'],
      teacherId: json['teacherId'],
      examTitle: json['examTitle'],
      answers: (json['answers'] as List)
          .map((a) => MCQAnswer.fromJson(a))
          .toList(),
      imagePath: json['imagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      examMetadata: json['examMetadata'],
    );
  }
}