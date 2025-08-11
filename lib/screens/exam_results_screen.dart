import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/mcq_provider.dart';
import '../models/mcq_answer.dart';
import '../models/student_response.dart';
import '../widgets/stats_card.dart';
import '../services/excel_service.dart';

class ExamResultsScreen extends StatefulWidget {
  final AnswerKey exam;

  const ExamResultsScreen({super.key, required this.exam});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load exam results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MCQProvider>(context, listen: false);
      provider.loadExamResults(widget.exam.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MCQProvider>(
      builder: (context, provider, child) {
        final stats = provider.getExamStatistics(widget.exam.id);
        
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.exam.examTitle),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadExamResults(widget.exam.id),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'generate_report',
                    child: Row(
                      children: [
                        Icon(Icons.analytics),
                        SizedBox(width: 8),
                        Text('Generate Report'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_excel',
                    child: Row(
                      children: [
                        Icon(Icons.file_download),
                        SizedBox(width: 8),
                        Text('Export Excel'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'generate_report') {
                    _generateReport(provider);
                  } else if (value == 'export_excel') {
                    _exportExcel(provider);
                  }
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                Tab(icon: Icon(Icons.people), text: 'Students'),
                Tab(icon: Icon(Icons.quiz), text: 'Questions'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(provider, stats),
              _buildStudentsTab(provider),
              _buildQuestionsTab(provider),
            ],
          ),
          floatingActionButton: provider.isProcessing
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addStudentAnswers(provider),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Students'),
                ),
        );
      },
    );
  }

  Widget _buildOverviewTab(MCQProvider provider, Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Processing indicator
          if (provider.isProcessing) _buildProcessingCard(provider),
          
          // Stats cards
          if (stats.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Total Students',
                    value: stats['totalStudents'].toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Average Score',
                    value: '${stats['averageScore'].toStringAsFixed(1)}%',
                    icon: Icons.analytics,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Highest Score',
                    value: '${stats['highestScore'].toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Pass Rate',
                    value: '${stats['passRate'].toStringAsFixed(1)}%',
                    icon: Icons.check_circle,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          
          // Exam details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exam Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Title', widget.exam.examTitle),
                  _buildDetailRow('Questions', '${widget.exam.answers.length}'),
                  _buildDetailRow('Created', _formatDate(widget.exam.createdAt)),
                  _buildDetailRow('Exam ID', widget.exam.id.substring(0, 8)),
                ],
              ),
            ),
          ),
          
          if (provider.studentResults.isEmpty) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No student results yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add student answer sheets to see results',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _addStudentAnswers(provider),
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Student Answers'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentsTab(MCQProvider provider) {
    if (provider.studentResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No student results available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.studentResults.length,
      itemBuilder: (context, index) {
        final student = provider.studentResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getGradeColor(student.grade),
              child: Text(
                student.grade,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              student.studentName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score: ${student.percentage.toStringAsFixed(1)}%'),
                Text('${student.correctAnswers}/${student.totalQuestions} correct'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view_details',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'generate_report',
                  child: Row(
                    children: [
                      Icon(Icons.description),
                      SizedBox(width: 8),
                      Text('Individual Report'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'view_details') {
                  _showStudentDetails(student);
                } else if (value == 'generate_report') {
                  _generateStudentReport(provider, student);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionsTab(MCQProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.exam.answers.length,
      itemBuilder: (context, index) {
        final answer = widget.exam.answers[index];
        final questionStats = _getQuestionStats(provider, answer.questionNumber);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Q${answer.questionNumber}',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Correct Answer: ${answer.correctAnswer}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (questionStats.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${questionStats['correct']}/${questionStats['total']} students correct',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(questionStats['percentage']),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${questionStats['percentage'].toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcessingCard(MCQProvider provider) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.progressMessage,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            if (provider.progress > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: provider.progress),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addStudentAnswers(MCQProvider provider) async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (images.isEmpty) return;

    final studentNames = <String>[];
    for (int i = 0; i < images.length; i++) {
      final name = await _getStudentName(context, i + 1);
      if (name != null) {
        studentNames.add(name);
      } else {
        return; // User cancelled
      }
    }

    final imageFiles = images.map((xfile) => File(xfile.path)).toList();
    
    await provider.processStudentAnswers(
      examId: widget.exam.id,
      studentImages: imageFiles,
      studentNames: studentNames,
    );
  }

  Future<String?> _getStudentName(BuildContext context, int studentNumber) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Student $studentNumber Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Student Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.studentName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score: ${student.percentage.toStringAsFixed(1)}%'),
              Text('Grade: ${student.grade}'),
              Text('Correct: ${student.correctAnswers}/${student.totalQuestions}'),
              const SizedBox(height: 16),
              const Text('Question Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...student.responses.map((response) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('Q${response.questionNumber}: '),
                    Text(
                      response.selectedAnswer,
                      style: TextStyle(
                        color: response.isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!response.isCorrect) ...[
                      const Text(' ('),
                      Text(
                        widget.exam.answers
                            .firstWhere((a) => a.questionNumber == response.questionNumber)
                            .correctAnswer,
                        style: const TextStyle(color: Colors.green),
                      ),
                      const Text(')'),
                    ],
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _generateReport(MCQProvider provider) async {
    await provider.generateClassReport(examId: widget.exam.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report generated successfully!')),
      );
    }
  }

  void _exportExcel(MCQProvider provider) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Generating Excel report...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      await provider.generateClassReport(
        examId: widget.exam.id,
        generateExcel: true,
        generatePDF: false,
      );

      if (mounted && provider.currentClassReport?.excelFilePath != null) {
        final filePath = provider.currentClassReport!.excelFilePath!;
        
        // Show success message with file location
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Excel report generated successfully!'),
                const SizedBox(height: 4),
                Text(
                  'Location: ${filePath.split('/').last}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => _shareExcelFile(filePath),
            ),
            duration: const Duration(seconds: 5),
          ),
        );

        // Also show dialog with options
        _showExcelSuccessDialog(filePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate Excel report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExcelSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Report Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Excel report has been saved successfully!'),
            const SizedBox(height: 12),
            Text(
              'File: ${filePath.split('/').last}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${filePath.contains('/Download') ? 'Downloads folder' : 'App storage'}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareExcelFile(filePath);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _shareExcelFile(String filePath) async {
    try {
      // Import the service at the top of the file if not already imported
      final excelService = ExcelService();
      await excelService.shareExcelFile(filePath, widget.exam.examTitle);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generateStudentReport(MCQProvider provider, student) async {
    final filePath = await provider.generateStudentReport(
      student.studentId,
      student.examId,
    );
    
    if (mounted && filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved: ${filePath.split('/').last}')),
      );
    }
  }

  Map<String, dynamic> _getQuestionStats(MCQProvider provider, String questionNumber) {
    final results = provider.studentResults;
    if (results.isEmpty) return {};

    int correct = 0;
    int total = results.length;

    for (final result in results) {
      final response = result.responses.firstWhere(
        (r) => r.questionNumber == questionNumber,
        orElse: () => StudentResponse(
          studentId: '',
          studentName: '',
          questionNumber: questionNumber,
          selectedAnswer: '',
          isCorrect: false,
        ),
      );
      if (response.isCorrect == true) correct++;
    }

    return {
      'correct': correct,
      'total': total,
      'percentage': (correct / total) * 100,
    };
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A': return Colors.green;
      case 'B': return Colors.lightGreen;
      case 'C': return Colors.orange;
      case 'D': return Colors.deepOrange;
      default: return Colors.red;
    }
  }

  Color _getDifficultyColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}