import 'package:flutter/material.dart';
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

  Future<void> _importPlan() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'xlsx', 'txt'],
      );

      if (result != null) {
        String path = result.files.single.path!;
        ImportResult importResult = await _importEngine.parseFile(path);
        
        if (!importResult.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Import Failed: ${importResult.error}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        if (mounted && importResult.plan != null) {
          _showEditablePreviewDialog(importResult.plan!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditablePreviewDialog(WeekPlan plan) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(plan.weekIdentifier, style: const TextStyle(color: Colors.white, fontSize: 18))),
              const Icon(Icons.edit, color: Colors.grey, size: 20),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: plan.days.length,
              itemBuilder: (context, dayIdx) {
                final day = plan.days[dayIdx];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(day.day, style: const TextStyle(color: Color(0xFFBB86FC), fontWeight: FontWeight.bold)),
                    ),
                    ...day.tasks.asMap().entries.map((entry) {
                      int taskIdx = entry.key;
                      TaskBlock task = entry.value;
                      bool isLowQuality = task.label == 'Activity' || task.time == 'TBD';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isLowQuality ? Colors.orange.withValues(alpha: 0.1) : Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: isLowQuality ? Border.all(color: Colors.orange.withValues(alpha: 0.5)) : null,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    decoration: const InputDecoration(isDense: true, labelText: 'Label', labelStyle: TextStyle(color: Colors.grey)),
                                    controller: TextEditingController(text: task.label),
                                    onChanged: (val) => plan.days[dayIdx].tasks[taskIdx] = task.copyWith(label: val),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    decoration: const InputDecoration(isDense: true, labelText: 'Time', labelStyle: TextStyle(color: Colors.grey)),
                                    controller: TextEditingController(text: task.time),
                                    onChanged: (val) => plan.days[dayIdx].tasks[taskIdx] = task.copyWith(time: val),
                                  ),
                                ),
                              ],
                            ),
                            if (isLowQuality)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('⚠️ Please review activity details', style: TextStyle(color: Colors.orange, fontSize: 10)),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBB86FC)),
              onPressed: () async {
                await _planService.savePlan(plan);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New Plan Applied Successfully!')),
                  );
                }
              },
              child: const Text('CONFIRM & APPLY', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetToDefault() async {
    await _planService.resetPlan();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restored to default plan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PLANNER IMPORT ENGINE',
              style: TextStyle(color: Colors.grey, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildSettingsTile(
              icon: Icons.upload_file,
              title: 'Import Planner',
              subtitle: 'Supports JSON, TXT, CSV, XLSX',
              onTap: _importPlan,
            ),
            const SizedBox(height: 10),
            _buildSettingsTile(
              icon: Icons.restore,
              title: 'Restore Default',
              subtitle: 'Reset to original system plan',
              onTap: _resetToDefault,
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
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
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
