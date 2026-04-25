import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/schedule_model.dart';
import '../services/plan_service.dart';
import '../services/import_engine.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PlanService _planService = PlanService();
  final ImportEngine _importEngine = ImportEngine();
  List<String> _importLogs = [];
  bool _isImporting = false;

  Future<void> _importPlan() async {
    setState(() {
      _isImporting = true;
      _importLogs = ['Initializing file picker...'];
    });

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'xlsx'],
      );

      if (result != null) {
        String path = result.files.single.path!;
        setState(() => _importLogs.add('File selected: ${path.split("/").last}. Analyzing...'));
        
        ImportResult importResult = await _importEngine.parseFile(path);
        
        setState(() {
          _importLogs = importResult.logs;
          _isImporting = false;
        });

        if (!importResult.success) {
          _showErrorSnackBar(importResult.error ?? 'Analysis failed');
          return;
        }

        if (mounted && importResult.plan != null) {
          _showEditablePreviewDialog(importResult.plan!);
        }
      } else {
        setState(() {
          _importLogs.add('Import cancelled.');
          _isImporting = false;
        });
      }
    } catch (e) {
      setState(() => _isImporting = false);
      _showErrorSnackBar('Import engine error: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'LOGS', textColor: Colors.white, onPressed: _showLogsDialog),
      ),
    );
  }

  void _showLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Analysis Details', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _importLogs.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '> ${_importLogs[i]}',
                style: const TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  void _showEditablePreviewDialog(WeekPlan plan) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text('Review: ${plan.weekIdentifier}', style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: plan.days.length,
              itemBuilder: (context, dIdx) {
                final day = plan.days[dIdx];
                return ExpansionTile(
                  initiallyExpanded: dIdx == 0,
                  title: Text(day.day, style: const TextStyle(color: Color(0xFFBB86FC), fontWeight: FontWeight.bold)),
                  subtitle: Text('${day.tasks.length} activities found', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  children: day.tasks.map((t) => ListTile(
                    dense: true,
                    title: Text(t.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text('${t.time} | ${t.task ?? "No description"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  )).toList(),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('DISCARD', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBB86FC)),
              onPressed: () async {
                await _planService.savePlan(plan);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan Activated!')));
                }
              },
              child: const Text('ACTIVATE PLAN', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _copyTemplate() {
    Clipboard.setData(const ClipboardData(text: ImportEngine.canonicalJsonTemplate));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON Template copied to clipboard!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Import Planner', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('METHODS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 15),
                _buildActionCard(
                  icon: Icons.upload_file,
                  title: 'Upload Excel (.xlsx)',
                  subtitle: 'Optimized for Week1_Life_System_Planner',
                  onTap: _isImporting ? () {} : _importPlan,
                ),
                const SizedBox(height: 10),
                _buildActionCard(
                  icon: Icons.code,
                  title: 'Custom JSON Schema',
                  subtitle: 'Use for custom structures',
                  onTap: _isImporting ? () {} : _importPlan,
                ),
                const SizedBox(height: 10),
                _buildActionCard(
                  icon: Icons.content_copy,
                  title: 'Copy JSON Template',
                  subtitle: 'Copy canonical structure to clipboard',
                  onTap: _copyTemplate,
                ),
                const SizedBox(height: 30),
                const Text('MAINTENANCE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 15),
                _buildActionCard(
                  icon: Icons.refresh,
                  title: 'Restore Default Plan',
                  subtitle: 'Reset to original system defaults',
                  onTap: () async {
                    await _planService.resetPlan();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('System defaults restored.')));
                  },
                  color: Colors.redAccent,
                ),
                if (_importLogs.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ANALYSIS CONSOLE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () => setState(() => _importLogs = []), child: const Text('CLEAR', style: TextStyle(fontSize: 10))),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
                    child: Text(_importLogs.join('\n'), style: const TextStyle(color: Colors.green, fontSize: 10, fontFamily: 'monospace')),
                  ),
                ],
              ],
            ),
          ),
          if (_isImporting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFBB86FC)),
                    SizedBox(height: 20),
                    Text('Analyzing file structure...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: _isImporting ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: color ?? const Color(0xFFBB86FC)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
