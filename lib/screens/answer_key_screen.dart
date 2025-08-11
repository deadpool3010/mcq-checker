import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/mcq_provider.dart';

class AnswerKeyScreen extends StatefulWidget {
  const AnswerKeyScreen({super.key});

  @override
  State<AnswerKeyScreen> createState() => _AnswerKeyScreenState();
}

class _AnswerKeyScreenState extends State<AnswerKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _examTitleController = TextEditingController();
  final _questionsController = TextEditingController(text: '50');
  final _answerFormatController = TextEditingController(text: 'A,B,C,D');
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  String _selectedSource = 'camera';
  
  @override
  void dispose() {
    _examTitleController.dispose();
    _questionsController.dispose();
    _answerFormatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MCQProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Upload Answer Key'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions
                  Card(
                    color: Colors.blue.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Instructions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Take a clear photo of your answer key\n'
                            '2. Ensure good lighting and focus\n'
                            '3. Include all questions and answers\n'
                            '4. Avoid shadows and reflections',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Exam Title
                  TextFormField(
                    controller: _examTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Exam Title',
                      hintText: 'e.g., Math Quiz Chapter 5',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an exam title';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Number of Questions
                  TextFormField(
                    controller: _questionsController,
                    decoration: const InputDecoration(
                      labelText: 'Number of Questions',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the number of questions';
                      }
                      final num = int.tryParse(value.trim());
                      if (num == null || num <= 0 || num > 200) {
                        return 'Please enter a valid number (1-200)';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Answer Format
                  TextFormField(
                    controller: _answerFormatController,
                    decoration: const InputDecoration(
                      labelText: 'Answer Format',
                      hintText: 'e.g., A,B,C,D or 1,2,3,4',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.format_list_bulleted),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the answer format';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Image Source Selection
                  const Text(
                    'Select Image Source',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Camera'),
                          value: 'camera',
                          groupValue: _selectedSource,
                          onChanged: (value) {
                            setState(() => _selectedSource = value!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Gallery'),
                          value: 'gallery',
                          groupValue: _selectedSource,
                          onChanged: (value) {
                            setState(() => _selectedSource = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Image Selection/Display
                  if (_selectedImage == null)
                    Card(
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Tap to select answer key image',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Change Image'),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() => _selectedImage = null);
                                  },
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Process Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: provider.isProcessing || _selectedImage == null
                          ? null
                          : _processAnswerKey,
                      icon: provider.isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload),
                      label: Text(
                        provider.isProcessing ? 'Processing...' : 'Process Answer Key',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  
                  // Progress indicator
                  if (provider.isProcessing) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              provider.progressMessage,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (provider.progress > 0) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(value: provider.progress),
                              const SizedBox(height: 4),
                              Text(
                                '${(provider.progress * 100).toInt()}% complete',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: _selectedSource == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _processAnswerKey() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      return;
    }

    final provider = Provider.of<MCQProvider>(context, listen: false);
    
    try {
      await provider.processAnswerKey(
        imageFile: _selectedImage!,
        examTitle: _examTitleController.text.trim(),
        expectedQuestions: int.parse(_questionsController.text.trim()),
        answerFormat: _answerFormatController.text.trim(),
        examMetadata: {
          'created_via': 'mobile_app',
          'image_source': _selectedSource,
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer key processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Show results dialog
        if (provider.currentAnswerKey != null) {
          _showResultsDialog(provider.currentAnswerKey!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process answer key: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResultsDialog(answerKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Answer Key Processed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exam: ${answerKey.examTitle}'),
            Text('Questions detected: ${answerKey.answers.length}'),
            const SizedBox(height: 16),
            const Text(
              'What would you like to do next?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
              // Navigate to student answers screen
              Navigator.pushNamed(context, '/student-answers', arguments: answerKey);
            },
            child: const Text('Add Student Answers'),
          ),
        ],
      ),
    );
  }
}