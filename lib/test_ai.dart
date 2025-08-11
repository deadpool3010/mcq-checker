import 'dart:io';
import 'services/ai_service.dart';

Future<void> testAI() async {
  try {
    print('Testing AI service...');
    final aiService = AIService();
    
    // Create a dummy file for testing (you'll need to replace this with actual image)
    final dummyFile = File('test_image.jpg');
    
    if (!await dummyFile.exists()) {
      print('Please add a test image file named test_image.jpg to test');
      return;
    }
    
    final results = await aiService.extractAnswerKey(
      dummyFile,
      expectedQuestions: 10,
      answerFormat: 'A,B,C,D',
    );
    
    print('Results: $results');
    
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}