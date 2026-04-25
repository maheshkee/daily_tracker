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

  Future<void> _importPlan() async {
    setState(() => _importLogs = ['Starting import...']);
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'xlsx'],
      );

      if (result != null) {
        String path = result.files.single.path!;
        ImportResult importResult = await _importEngine.parseFile(path);
        
        setState(() => _importLogs = importResult.logs);

        if (!importResult.success) {
          _showErrorSnackBar(importResult.error ?? 'Unknown error');
          return;
        }

        if (mounted && importResult.plan != null) {
          _showEditablePreviewDialog(importResult.plan!);
        }
      } else {
        setState(() => _importLogs.add('Import cancelled by user.'));
      }
    } catch (e) {
      _showErrorSnackBar('Unexpected Error: $e');
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
        title: const Text('Import Debug Logs', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _importLogs.length,
            itemBuilder: (context, i) => Text(
              _importLogs[i],
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace'),
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
                  title: Text(day.day, style: const TextStyle(color: Color(0xFFBB86FC))),
                  children: day.tasks.map((t) => ListTile(
                    title: Text(t.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text('${t.time} | ${t.task ?? ""}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  )).toList(),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBB86FC)),
              onPressed: () async {
                await _planService.savePlan(plan);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan Applied!')));
                }
              },
              child: const Text('CONFIRM', style: TextStyle(color: Colors.black)),
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
        title: const Text('System Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IMPORT DATA', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildActionCard(
              icon: Icons.file_upload,
              title: 'Upload Planner',
              subtitle: 'Supports .json and .xlsx',
              onTap: _importPlan,
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              icon: Icons.code,
              title: 'Copy JSON Template',
              subtitle: 'Use this schema for custom plans',
              onTap: _copyTemplate,
            ),
            const SizedBox(height: 30),
            const Text('SYSTEM', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildActionCard(
              icon: Icons.restore,
              title: 'Restore Default',
              subtitle: 'Reset to original Week 1 plan',
              onTap: () async {
                await _planService.resetPlan();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default restored.')));
              },
              color: Colors.redAccent,
            ),
            if (_importLogs.isNotEmpty) ...[
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('RECENT IMPORT LOGS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () => setState(() => _importLogs = []), child: const Text('CLEAR', style: TextStyle(fontSize: 10))),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                child: Text(_importLogs.join('\n'), style: const TextStyle(color: Colors.green, fontSize: 10, fontFamily: 'monospace')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}
