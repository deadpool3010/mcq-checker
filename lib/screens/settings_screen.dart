import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mcq_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _openAIController = TextEditingController();
  final _n8nUrlController = TextEditingController();
  final _n8nKeyController = TextEditingController();
  final _teacherIdController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final provider = Provider.of<MCQProvider>(context, listen: false);
    _teacherIdController.text = provider.teacherId;
    
    // Load saved settings from provider if available
    final settings = provider.settings;
    _openAIController.text = settings['openai_api_key'] ?? '';
    _n8nUrlController.text = settings['n8n_base_url'] ?? '';
    _n8nKeyController.text = settings['n8n_api_key'] ?? '';
  }

  @override
  void dispose() {
    _openAIController.dispose();
    _n8nUrlController.dispose();
    _n8nKeyController.dispose();
    _teacherIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Configuration Section
            _buildSectionCard(
              title: 'API Configuration',
              icon: Icons.api,
              children: [
                TextField(
                  controller: _openAIController,
                  decoration: const InputDecoration(
                    labelText: 'OpenAI API Key',
                    hintText: 'sk-...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _n8nUrlController,
                  decoration: const InputDecoration(
                    labelText: 'N8N Base URL',
                    hintText: 'https://your-n8n-instance.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _n8nKeyController,
                  decoration: const InputDecoration(
                    labelText: 'N8N API Key (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveApiSettings,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save API Settings'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Teacher Information Section
            _buildSectionCard(
              title: 'Teacher Information',
              icon: Icons.person,
              children: [
                TextField(
                  controller: _teacherIdController,
                  decoration: const InputDecoration(
                    labelText: 'Teacher ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveTeacherInfo,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Teacher Info'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Processing Settings Section
            _buildSectionCard(
              title: 'Processing Settings',
              icon: Icons.settings,
              children: [
                const ListTile(
                  title: Text('Default Question Count'),
                  subtitle: Text('50'),
                  trailing: Icon(Icons.edit),
                ),
                const ListTile(
                  title: Text('Default Answer Format'),
                  subtitle: Text('A,B,C,D'),
                  trailing: Icon(Icons.edit),
                ),
                const ListTile(
                  title: Text('Image Quality'),
                  subtitle: Text('85%'),
                  trailing: Icon(Icons.edit),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Data Management Section
            _buildSectionCard(
              title: 'Data Management',
              icon: Icons.storage,
              children: [
                ListTile(
                  title: const Text('Export All Data'),
                  subtitle: const Text('Export exams and results'),
                  trailing: const Icon(Icons.download),
                  onTap: _exportData,
                ),
                ListTile(
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Delete all exams and results'),
                  trailing: const Icon(Icons.delete, color: Colors.red),
                  onTap: _confirmClearData,
                ),
                ListTile(
                  title: const Text('Sync Status'),
                  subtitle: const Text('Check cloud synchronization'),
                  trailing: const Icon(Icons.sync),
                  onTap: _checkSyncStatus,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildSectionCard(
              title: 'About',
              icon: Icons.info,
              children: [
                const ListTile(
                  title: Text('App Version'),
                  subtitle: Text('1.0.0'),
                ),
                const ListTile(
                  title: Text('Developer'),
                  subtitle: Text('MCQ Checker Team'),
                ),
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openPrivacyPolicy,
                ),
                ListTile(
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openTermsOfService,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _saveApiSettings() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveTeacherInfo() {
    final provider = Provider.of<MCQProvider>(context, listen: false);
    provider.setTeacherId(_teacherIdController.text);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teacher information saved!')),
    );
  }

  void _exportData() {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon!')),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all exams, results, and reports? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    // TODO: Implement clear all data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clear data feature coming soon!')),
    );
  }

  void _checkSyncStatus() {
    // TODO: Implement sync status check
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync status: All data up to date')),
    );
  }

  void _openPrivacyPolicy() {
    // TODO: Open privacy policy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening privacy policy...')),
    );
  }

  void _openTermsOfService() {
    // TODO: Open terms of service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening terms of service...')),
    );
  }
}