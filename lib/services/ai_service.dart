import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mcq_answer.dart';
import '../models/student_response.dart';

class AIService {
  static const String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _visionEndpoint = '/models/gemini-1.5-flash:generateContent';
  
  // TODO: Replace with your actual Gemini API key
  static const String _geminiApiKey = '';

  AIService();

  /// Extract answer key from uploaded image using Gemini Vision
  Future<List<MCQAnswer>> extractAnswerKey(File imageFile, {
    int expectedQuestions = 50,
    String answerFormat = 'A,B,C,D'
  }) async {
    try {
      // Use Gemini Vision for answer extraction
      final aiResults = await _extractWithGemini(
        imageFile, 
        isAnswerKey: true,
        expectedQuestions: expectedQuestions,
        answerFormat: answerFormat
      );
      
      return aiResults;
    } catch (e) {
      throw Exception('Failed to extract answer key: $e');
    }
  }

  /// Extract student answers from uploaded image
  Future<List<StudentResponse>> extractStudentAnswers(
    File imageFile, 
    String studentId,
    String studentName,
    List<MCQAnswer> answerKey, {
    String answerFormat = 'A,B,C,D'
  }) async {
    try {
      // Extract answers using Gemini Vision
      final extractedAnswers = await _extractWithGemini(
        imageFile, 
        isAnswerKey: false,
        expectedQuestions: answerKey.length,
        answerFormat: answerFormat
      );
      
      // Compare with answer key and create student responses
      return _createStudentResponses(
        extractedAnswers, 
        answerKey, 
        studentId, 
        studentName
      );
    } catch (e) {
      throw Exception('Failed to extract student answers: $e');
    }
  }



  /// Extract answers using Gemini Vision API
  Future<List<MCQAnswer>> _extractWithGemini(
    File imageFile, {
    required bool isAnswerKey,
    required int expectedQuestions,
    required String answerFormat
  }) async {
    try {
      print('Starting Gemini API call...');
      print('API Key length: ${_geminiApiKey.length}');
      print('Expected questions: $expectedQuestions');
      
      final bytes = await imageFile.readAsBytes();
      print('Image size: ${bytes.length} bytes');
      
      final base64Image = base64Encode(bytes);
      print('Base64 image length: ${base64Image.length}');
      
      final prompt = isAnswerKey 
          ? _buildAnswerKeyPrompt(expectedQuestions, answerFormat)
          : _buildStudentAnswerPrompt(expectedQuestions, answerFormat);

      print('Prompt: $prompt');

      final response = await http.post(
        Uri.parse('$_geminiBaseUrl$_visionEndpoint?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt,
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.1,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 1000,
          },
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Add null checks for Gemini response structure
        if (data['candidates'] == null || 
            data['candidates'].isEmpty || 
            data['candidates'][0]['content'] == null ||
            data['candidates'][0]['content']['parts'] == null ||
            data['candidates'][0]['content']['parts'].isEmpty ||
            data['candidates'][0]['content']['parts'][0]['text'] == null) {
          throw Exception('Invalid Gemini API response structure: ${response.body}');
        }
        
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        print('Gemini Response content: $content');
        return _parseAIResponse(content);
      } else {
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error in _extractWithGemini: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  String _buildAnswerKeyPrompt(int expectedQuestions, String answerFormat) {
    return '''
    Analyze this MCQ answer key image and extract all the correct answers.
    
    Look for patterns like:
    - "1-A", "2-B", "3-C" 
    - "1. A", "2. B", "3. C"
    - "1) A", "2) B", "3) C"
    - Or any similar format showing question number and answer
    
    Expected: Question numbers 1-$expectedQuestions with answers from [$answerFormat]
    
    Please return ONLY a JSON array in this exact format:
    [
      {"questionNumber": "1", "correctAnswer": "A", "confidence": 0.95},
      {"questionNumber": "2", "correctAnswer": "B", "confidence": 0.90}
    ]
    
    Important:
    - Return ONLY the JSON array, no other text
    - Only include questions you can clearly identify
    - Confidence should be between 0.0 and 1.0 based on how clear the answer is
    - Use uppercase letters for answers (A, B, C, D)
    - Question numbers should be strings
    ''';
  }

  String _buildStudentAnswerPrompt(int expectedQuestions, String answerFormat) {
    return '''
    Analyze this student's MCQ answer sheet and extract all the selected answers.
    
    Look for:
    - Filled/darkened bubbles (●)
    - Checkmarks (✓) 
    - Circled letters
    - Any clear indication of selected answers
    - Patterns like "1-A", "2-B" if written
    
    Expected: Question numbers 1-$expectedQuestions with answers from [$answerFormat]
    
    Please return ONLY a JSON array in this exact format:
    [
      {"questionNumber": "1", "selectedAnswer": "A", "confidence": 0.95},
      {"questionNumber": "2", "selectedAnswer": "B", "confidence": 0.90}
    ]
    
    Important:
    - Return ONLY the JSON array, no other text
    - Only include questions where you can clearly identify the selected answer
    - Confidence should be between 0.0 and 1.0 based on how clear the selection is
    - Use uppercase letters for answers (A, B, C, D)
    - Question numbers should be strings
    ''';
  }

  List<MCQAnswer> _parseAIResponse(String content) {
    try {
      // Extract JSON from the response (in case there's additional text)
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(content);
      if (jsonMatch == null) {
        throw Exception('No JSON found in AI response');
      }
      
      final jsonString = jsonMatch.group(0)!;
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((item) {
        return MCQAnswer(
          questionNumber: item['questionNumber'].toString(),
          correctAnswer: item['correctAnswer']?.toString().toUpperCase() ?? 
                        item['selectedAnswer']?.toString().toUpperCase() ?? '',
          confidence: (item['confidence'] ?? 0.8).toDouble(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse AI response: $e');
    }
  }



  List<StudentResponse> _createStudentResponses(
    List<MCQAnswer> extractedAnswers,
    List<MCQAnswer> answerKey,
    String studentId,
    String studentName
  ) {
    List<StudentResponse> responses = [];
    
    // Create a map of correct answers for quick lookup
    Map<String, String> correctAnswers = {};
    for (var answer in answerKey) {
      correctAnswers[answer.questionNumber] = answer.correctAnswer;
    }
    
    for (var extracted in extractedAnswers) {
      final correctAnswer = correctAnswers[extracted.questionNumber];
      final isCorrect = correctAnswer != null && 
                       correctAnswer == extracted.correctAnswer;
      
      responses.add(StudentResponse(
        studentId: studentId,
        studentName: studentName,
        questionNumber: extracted.questionNumber,
        selectedAnswer: extracted.correctAnswer, // This is actually the selected answer
        confidence: extracted.confidence,
        isCorrect: isCorrect,
      ));
    }
    
    return responses;
  }
}