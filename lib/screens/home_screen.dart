import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mcq_provider.dart';
import '../widgets/exam_card.dart';
import '../widgets/stats_card.dart';
import 'answer_key_screen.dart';
import 'exam_results_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  Timer? _autoRefreshTimer;
  static const Duration _autoRefreshInterval = Duration(minutes: 5); // Auto-refresh every 5 minutes
  
  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen initState called');
    _tabController = TabController(length: 3, vsync: this);
    
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // MOST BASIC AUTO-REFRESH: Just trigger after 3 seconds no matter what
    Timer(const Duration(seconds: 3), () {
      print('⏰ BASIC TIMER: 3 seconds passed, attempting auto-refresh...');
      final provider = Provider.of<MCQProvider>(context, listen: false);
      print('⏰ Provider state: isInitialized=${provider.isInitialized}, isProcessing=${provider.isProcessing}');
      if (mounted && provider.isInitialized && !provider.isProcessing) {
        print('⏰ BASIC TIMER: Triggering refresh now!');
        provider.refresh();
      } else {
        print('⏰ BASIC TIMER: Conditions not met for auto-refresh');
      }
    });
    
    // Simple auto-click refresh button when app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📱 HomeScreen postFrameCallback - checking initialization...');
      _initializeServiceIfNeeded();
      _autoClickRefreshButton();
      _startAutoRefresh();
    });
  }

  // Simple method to auto-click the refresh button with retry logic
  void _autoClickRefreshButton() {
    // Try multiple times with increasing delays to ensure it works after complete app restart
    final delays = [300, 800, 1500, 3000]; // milliseconds - different from provider delays
    
    for (int i = 0; i < delays.length; i++) {
      Future.delayed(Duration(milliseconds: delays[i]), () {
        if (mounted) {
          final provider = Provider.of<MCQProvider>(context, listen: false);
          print('🔄 HomeScreen auto-refresh attempt ${i + 1} (${delays[i]}ms)...');
          print('   - mounted: $mounted, isInitialized: ${provider.isInitialized}, isProcessing: ${provider.isProcessing}');
          
          if (provider.isInitialized && !provider.isProcessing) {
            provider.refresh().then((_) {
              print('✅ HomeScreen auto-refresh successful on attempt ${i + 1}');
              
              // Show user that data is loading (only on first successful attempt)
              if (i == 0 && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📱 Loading data automatically...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }).catchError((error) {
              print('❌ HomeScreen auto-refresh failed on attempt ${i + 1}: $error');
            });
            return; // Stop trying after first success
          }
        }
      });
    }
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Auto-click refresh button when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      print('App resumed - auto-clicking refresh button...');
      _autoClickRefreshButton();
    }
  }

  void _startAutoRefresh() {
    // Cancel existing timer if any
    _autoRefreshTimer?.cancel();
    
    // Start periodic refresh
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
      _refreshDataIfNeeded();
    });
  }

  void _refreshDataIfNeeded() {
    final provider = Provider.of<MCQProvider>(context, listen: false);
    if (provider.isInitialized && !provider.isProcessing) {
      print('Auto-refreshing app data...');
      provider.refresh().then((_) {
        // Show subtle notification that data was refreshed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Data refreshed'),
                ],
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
            ),
          );
        }
      }).catchError((error) {
        // Show error if refresh fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Auto-refresh failed: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  void _toggleAutoRefresh() {
    if (_autoRefreshTimer?.isActive == true) {
      // Pause auto-refresh
      _autoRefreshTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-refresh paused'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Resume auto-refresh
      _startAutoRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-refresh resumed (every 5 minutes)'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    setState(() {}); // Update UI to reflect the change
  }

  void _initializeServiceIfNeeded() {
    final provider = Provider.of<MCQProvider>(context, listen: false);
    print('🔍 Checking if service is initialized: ${provider.isInitialized}');
    if (!provider.isInitialized) {
      print('❌ Service not initialized - showing dialog');
      _showInitializationDialog();
    } else {
      print('✅ Service is initialized - ready for auto-refresh');
    }
  }

  void _showInitializationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const InitializationDialog(),
    );
  }

  @override
  void dispose() {
    // Clean up resources
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MCQProvider>(
      builder: (context, provider, child) {
        
        
        

        
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text(
                  'MCQ Checker',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (provider.isProcessing) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            actions: [
              Builder(
                builder: (context) {
                 
                  
                  
                  return IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: provider.isProcessing ? Colors.grey : null,
                    ),
                    onPressed: provider.isProcessing ? null : () {
                      print('🔄 Manual refresh button clicked');
                      provider.refresh();
                    },
                    tooltip: 'Manual Refresh',
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                      break;
                    case 'toggle_auto_refresh':
                      _toggleAutoRefresh();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_auto_refresh',
                    child: Row(
                      children: [
                        Icon(_autoRefreshTimer?.isActive == true 
                          ? Icons.pause_circle 
                          : Icons.play_circle),
                        const SizedBox(width: 8),
                        Text(_autoRefreshTimer?.isActive == true 
                          ? 'Pause Auto-Refresh' 
                          : 'Resume Auto-Refresh'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                Tab(icon: Icon(Icons.assignment), text: 'Exams'),
                Tab(icon: Icon(Icons.analytics), text: 'Reports'),
              ],
            ),
          ),
          body: provider.isInitialized
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(provider),
                    _buildExamsTab(provider),
                    _buildReportsTab(provider),
                  ],
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Please configure API settings',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
          floatingActionButton: provider.isInitialized && !provider.isProcessing
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnswerKeyScreen()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('New Exam'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDashboardTab(MCQProvider provider) {
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Processing indicator
          if (provider.isProcessing) _buildProcessingCard(provider),
          
          // Error display
          if (provider.error != null) _buildErrorCard(provider),
          
          // Quick stats
          _buildQuickStats(provider),
          
          const SizedBox(height: 24),
          
          // Recent activity
          _buildRecentActivity(provider),
        ],
      ),
    );
  }

  Widget _buildExamsTab(MCQProvider provider) { 
    
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: provider.teacherExams.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No exams created yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first exam',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.teacherExams.length,
              itemBuilder: (context, index) {
                final exam = provider.teacherExams[index];
                return ExamCard(
                  exam: exam,
                  onTap: () => _openExamResults(exam),
                  onDelete: () => _confirmDeleteExam(provider, exam.id),
                );
              },
            ),
    );
  }

  Widget _buildReportsTab(MCQProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: provider.teacherReports.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No reports generated yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.teacherReports.length,
              itemBuilder: (context, index) {
                final report = provider.teacherReports[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.analytics, color: Colors.green),
                    title: Text(report.examTitle),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generated: ${_formatDate(report.generatedAt)}'),
                        Text('${report.statistics.totalStudents} students'),
                      ],
                    ),
                    trailing: Text(
                      '${report.statistics.averageScore.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => _openReportDetails(report),
                  ),
                );
              },
            ),
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
              LinearProgressIndicator(
                value: provider.progress,
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 4),
              Text(
                '${(provider.progress * 100).toInt()}% complete',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(MCQProvider provider) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => provider.clearError(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(MCQProvider provider) {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: 'Total Exams',
            value: provider.teacherExams.length.toString(),
            icon: Icons.assignment,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            title: 'Reports',
            value: provider.teacherReports.length.toString(),
            icon: Icons.analytics,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(MCQProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (provider.teacherExams.isEmpty && provider.teacherReports.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ...provider.teacherExams.take(3).map((exam) => Card(
            child: ListTile(
              leading: const Icon(Icons.assignment, color: Colors.blue),
              title: Text(exam.examTitle),
              subtitle: Text('Created: ${_formatDate(exam.createdAt)}'),
              trailing: Text('${exam.answers.length} questions'),
              onTap: () => _openExamResults(exam),
            ),
          )),
      ],
    );
  }

  void _openExamResults(exam) {
    final provider = Provider.of<MCQProvider>(context, listen: false);
    provider.setCurrentExam(exam);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamResultsScreen(exam: exam),
      ),
    );
  }

  void _openReportDetails(report) {
    // TODO: Implement report details screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report details coming soon!')),
    );
  }

  void _confirmDeleteExam(MCQProvider provider, String examId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: const Text(
          'Are you sure you want to delete this exam? This will also delete all student results and reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteExam(examId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class InitializationDialog extends StatefulWidget {
  const InitializationDialog({super.key});

  @override
  State<InitializationDialog> createState() => _InitializationDialogState();
}

class _InitializationDialogState extends State<InitializationDialog> {
  final _openAIController = TextEditingController();
  final _n8nUrlController = TextEditingController();
  final _n8nKeyController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Setup API Configuration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _openAIController,
              decoration: const InputDecoration(
                labelText: 'OpenAI API Key *',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _n8nUrlController,
              decoration: const InputDecoration(
                labelText: 'N8N Base URL *',
                hintText: 'https://your-n8n-instance.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _n8nKeyController,
              decoration: const InputDecoration(
                labelText: 'N8N API Key (optional)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'You can change these settings later in the Settings screen.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _initialize,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Initialize'),
        ),
      ],
    );
  }

  void _initialize() async {
    if (_openAIController.text.isEmpty || _n8nUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<MCQProvider>(context, listen: false);
      await provider.initializeService(
        n8nBaseUrl: _n8nUrlController.text,
        n8nApiKey: _n8nKeyController.text.isNotEmpty ? _n8nKeyController.text : null,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service initialized successfully!')),
        );
        
        // Auto-click refresh button after initialization is complete
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            print('🔄 Auto-clicking refresh button after initialization...');
            provider.refresh();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _openAIController.dispose();
    _n8nUrlController.dispose();
    _n8nKeyController.dispose();
    super.dispose();
  }
}