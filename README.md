# MCQ Checker - AI-Powered Answer Sheet Evaluation

A comprehensive mobile application for teachers to automatically check Multiple Choice Questions (MCQ) answer sheets using AI image processing and generate detailed reports.

## 🚀 Features

### Core Functionality
- **AI-Powered Answer Recognition**: Uses OpenAI Vision API and Google ML Kit for accurate answer extraction
- **Answer Key Processing**: Upload and process teacher's answer key images
- **Student Answer Evaluation**: Batch process multiple student answer sheets
- **Automated Grading**: Calculate scores, grades, and statistics automatically
- **Excel Report Generation**: Generate comprehensive class reports and individual student reports
- **Real-time Progress Tracking**: Monitor processing progress with detailed feedback

### Advanced Features
- **N8N Workflow Integration**: Automate notifications, data backup, and quality checks
- **Local Database Storage**: SQLite database for offline functionality
- **Cloud Synchronization**: Optional cloud storage integration
- **Quality Assurance**: AI confidence scoring and suspicious result detection
- **Batch Processing**: Handle multiple student answer sheets efficiently
- **Statistical Analysis**: Comprehensive class and question-wise analytics

## 🏗️ Architecture

### Technology Stack
- **Frontend**: Flutter (Dart)
- **AI Services**: OpenAI GPT-4 Vision, Google ML Kit
- **Database**: SQLite (local), Firebase (cloud sync)
- **Automation**: N8N workflows
- **File Processing**: Excel generation, PDF reports
- **State Management**: Provider pattern

### Project Structure
```
lib/
├── models/                 # Data models
│   ├── mcq_answer.dart
│   ├── student_response.dart
│   └── class_report.dart
├── services/              # Business logic services
│   ├── ai_service.dart
│   ├── excel_service.dart
│   ├── n8n_service.dart
│   ├── database_service.dart
│   └── mcq_service.dart
├── providers/             # State management
│   └── mcq_provider.dart
├── screens/               # UI screens
│   ├── home_screen.dart
│   ├── answer_key_screen.dart
│   ├── exam_results_screen.dart
│   └── settings_screen.dart
├── widgets/               # Reusable UI components
│   ├── exam_card.dart
│   └── stats_card.dart
└── main.dart             # App entry point
```

## 🛠️ Setup and Installation

### Prerequisites
1. Flutter SDK (3.8.1 or higher)
2. OpenAI API key
3. N8N instance (optional)
4. Android/iOS development environment

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mcqchecker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys**
   - Launch the app and go to Settings
   - Enter your OpenAI API key
   - Configure N8N base URL (optional)

4. **Run the application**
   ```bash
   flutter run
   ```

## 📱 How to Use

### 1. Create Answer Key
1. Open the app and tap "New Exam"
2. Enter exam details (title, number of questions, answer format)
3. Take a photo of your answer key or select from gallery
4. The AI will process and extract answers automatically

### 2. Process Student Answers
1. Select an existing exam
2. Tap "Add Students" 
3. Select multiple student answer sheet images
4. Enter student names for each image
5. The system will process all answers and calculate scores

### 3. Generate Reports
1. Go to the exam results screen
2. Tap the menu and select "Generate Report"
3. Choose Excel and/or PDF format
4. Reports will be saved to device storage

### 4. View Analytics
- Class statistics (average, highest, lowest scores)
- Pass/fail rates and grade distribution
- Question-wise difficulty analysis
- Individual student performance details

## 🤖 AI Integration Details

### OpenAI Vision API
```dart
// Example API call for answer extraction
final response = await http.post(
  Uri.parse('https://api.openai.com/v1/chat/completions'),
  headers: {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'model': 'gpt-4-vision-preview',
    'messages': [
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': promptText},
          {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}},
        ],
      },
    ],
    'max_tokens': 1000,
    'temperature': 0.1,
  }),
);
```

### Google ML Kit Integration
- Text recognition for basic answer extraction
- Enhanced accuracy when combined with OpenAI Vision
- Offline processing capability
- Confidence scoring for quality assurance

## 🔄 N8N Workflow Integration

### Available Workflows
1. **Answer Key Upload**: Triggered when answer key is processed
2. **Student Processing**: Triggered when student answers are evaluated
3. **Report Generation**: Triggered when reports are created
4. **Quality Check**: Automated quality assurance checks
5. **Grade Alerts**: Send notifications to students/parents
6. **Data Backup**: Automated cloud backup workflows

### Example N8N Webhook
```javascript
// N8N webhook payload example
{
  "event": "answer_key_uploaded",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "teacherId": "teacher_001",
    "examTitle": "Math Quiz Chapter 5",
    "totalQuestions": 50,
    "extractedAnswers": [...],
    "metadata": {...}
  }
}
```

## 📊 Database Schema

### Answer Keys Table
```sql
CREATE TABLE answer_keys (
  id TEXT PRIMARY KEY,
  teacher_id TEXT NOT NULL,
  exam_title TEXT NOT NULL,
  answers TEXT NOT NULL,
  image_path TEXT NOT NULL,
  created_at TEXT NOT NULL,
  exam_metadata TEXT,
  synced INTEGER DEFAULT 0
);
```

### Student Results Table
```sql
CREATE TABLE student_results (
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
  synced INTEGER DEFAULT 0
);
```

## 📈 Scalability Features

### Performance Optimizations
- **Batch Processing**: Handle multiple images simultaneously
- **Image Compression**: Optimize images before AI processing
- **Local Caching**: Store processed results locally
- **Progressive Loading**: Load data incrementally
- **Background Processing**: Process images in background threads

### Cloud Integration
- **Firebase Storage**: Store images and reports in cloud
- **Firestore Database**: Sync data across devices
- **Cloud Functions**: Server-side processing for heavy tasks
- **Authentication**: Multi-teacher support with secure login

### N8N Automation Benefits
- **Automated Workflows**: Reduce manual tasks
- **Integration Hub**: Connect with email, SMS, Google Sheets
- **Quality Monitoring**: Automated quality checks and alerts
- **Data Pipeline**: Streamlined data processing workflows
- **Notification System**: Real-time alerts and updates

## 🔧 Configuration Options

### AI Service Configuration
```dart
// AI Service initialization
final aiService = AIService(
  openAIApiKey: 'your-openai-key',
  confidenceThreshold: 0.8,
  maxRetries: 3,
  timeoutSeconds: 30,
);
```

### N8N Service Configuration
```dart
// N8N Service initialization
final n8nService = N8NService(
  baseUrl: 'https://your-n8n-instance.com',
  apiKey: 'your-n8n-api-key', // optional
  enableWebhooks: true,
  retryFailedRequests: true,
);
```

## 📋 Supported Answer Formats

- **Multiple Choice**: A, B, C, D (default)
- **Numerical**: 1, 2, 3, 4
- **Custom Formats**: Configure your own answer options
- **Mixed Formats**: Different formats per question section

## 🎯 Quality Assurance

### AI Confidence Scoring
- Each extracted answer includes confidence score (0-1)
- Low confidence answers flagged for manual review
- Combined ML Kit + OpenAI for enhanced accuracy
- Quality metrics tracked and reported

### Error Handling
- Graceful handling of API failures
- Automatic retry mechanisms
- Offline mode with sync when online
- User-friendly error messages

## 🚀 Future Enhancements

### Planned Features
- [ ] Support for True/False questions
- [ ] Fill-in-the-blank question processing
- [ ] Voice-based answer input
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Blockchain-based result verification
- [ ] Integration with Learning Management Systems

### AI Improvements
- [ ] Custom-trained models for better accuracy
- [ ] Support for handwritten answers
- [ ] Automatic question detection
- [ ] Answer sheet layout recognition
- [ ] Real-time processing feedback

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Email: support@mcqchecker.com
- Documentation: [docs.mcqchecker.com](https://docs.mcqchecker.com)

## 🙏 Acknowledgments

- OpenAI for GPT-4 Vision API
- Google for ML Kit
- Flutter team for the amazing framework
- N8N community for workflow automation tools

---

**MCQ Checker** - Revolutionizing education through AI-powered assessment tools.